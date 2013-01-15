setMethod(
	f = "itemplot.internal",
	signature = signature(object = 'ExploratoryClass'),
	definition = function(object, item, type = 'trace', degrees = 45, ...)
	{  			
		x <- itemplot.main(object, item, type, degrees, ...)		        
		return(invisible(x))
	}
)

#------------------------------------------------------------------------------
setMethod(
	f = "itemplot.internal",
	signature = signature(object = 'ConfirmatoryClass'),
	definition = function(object, item, type = 'trace', degrees = 45, ...)
	{
	    x <- itemplot.main(object, item, type, degrees, ...)    	
	    return(invisible(x))
	}
)

#------------------------------------------------------------------------------
setMethod(
    f = "itemplot.internal",
    signature = signature(object = 'list'),
    definition = function(object, item, type = 'trace', degrees = 45, ...)
    {        
        newobject <- new('MultipleGroupClass', cmods=object, nfact=object[[1]]@nfact, 
                         groupNames=factor(names(object)))        
        x <- itemplot.internal(newobject, item, type, degrees, ...)    	
        return(invisible(x))
    }
)

#------------------------------------------------------------------------------
setMethod(
    f = "itemplot.internal",
    signature = signature(object = 'MultipleGroupClass'),
    definition = function(object, item, type = 'trace', degrees = 45, ...)
    {       
        Pinfo <- list()        
        gnames <- object@groupNames
        nfact <- object@nfact        
        K <- object@cmods[[1]]@pars[[item]]@ncat
        for(g in 1:length(gnames)){
            Pinfo[[g]] <- itemplot.main(object@cmods[[g]], item=item, type='RETURN', 
                                        degrees=degrees, ...)
            Pinfo[[g]]$group <- rep(gnames[g], nrow(Pinfo[[g]]))
        }        
        if(type == 'RE'){
            for(g in length(gnames):1)
                Pinfo[[g]]$info <- Pinfo[[g]]$info / Pinfo[[1]]$info
        }
        dat <- Pinfo[[1]]        
        for(g in 2:length(gnames))
            dat <- rbind(dat, Pinfo[[g]])           
        Plist <- unclass(dat[, 1:K])
        P <- c()
        dat2 <- dat[, (K+1):ncol(dat)]
        for(i in 1:length(Plist))
            P <- c(P, Plist[[i]])
        for(i in 2:length(Plist))
            dat2 <- rbind(dat2, dat[, (K+1):ncol(dat)])
        dat2$P <- P
        dat2$cat <- rep(as.character(0:(length(Plist)-1)), each = nrow(dat))
        if(nfact == 1){
            if(type == 'info')            
                return(lattice::xyplot(info ~ Theta, dat, group=group, type = 'l', 
                                       auto.key = TRUE, main = paste('Information for item', item), 
                                       ylab = expression(I(theta)), xlab = expression(theta), ...))            
            if(type == 'trace')
                return(lattice::xyplot(P ~ Theta | cat, dat2, group=group, type = 'l', 
                                auto.key = TRUE, main = paste("Item", item, "Trace"), 
                                ylab = expression(P(theta)), xlab = expression(theta), ...))
            if(type == 'RE')
                return(lattice::xyplot(info ~ Theta, dat, group=group, type = 'l', 
                                       auto.key = TRUE, main = paste('Relative efficiency for item', item), 
                                       ylab = expression(RE(theta)), xlab = expression(theta), ...))
        }
        if(nfact == 2){
            Names <- colnames(dat)
            Names[c(length(Names) - 2,length(Names) - 1)] <- c('Theta1', 'Theta2')
            Names2 <- colnames(dat2)
            Names2[2:3] <- c('Theta2', 'Theta1')
            colnames(dat) <- Names
            colnames(dat2) <- Names2            
            if(type == 'info')            
                return(lattice::wireframe(info ~ Theta1 + Theta2, data = dat, group=group, 
                                          main=paste("Item", item, "Information"), 
                                          zlab=expression(I(theta)), xlab=expression(theta[1]), 
                                          ylab=expression(theta[2]), 
                                          scales = list(arrows = FALSE), 
                                          auto.key = TRUE, ...))            
            if(type == 'trace')
                return(lattice::wireframe(P ~ Theta1 + Theta2|cat, data = dat2, group = group, 
                                          main = paste("Item", item, "Trace"), 
                                          zlab=expression(P(theta)), 
                                          xlab=expression(theta[1]), 
                                          ylab=expression(theta[2]), 
                                          scales = list(arrows = FALSE), 
                                          auto.key = TRUE, ...))   
            if(type == 'RE')            
                return(lattice::wireframe(info ~ Theta1 + Theta2, data = dat, group=group, 
                                          main=paste("Relative efficiency for item", item), 
                                          zlab=expression(RE(theta)), xlab=expression(theta[1]), 
                                          ylab=expression(theta[2]), 
                                          scales = list(arrows = FALSE), 
                                          auto.key = TRUE, ...))
        }
    }
)


itemplot.main <- function(x, item, type, degrees = 45, ...){        
    nfact <- ncol(x@F)
    if(nfact > 2) stop('Can not plot high dimensional models')
    if(nfact == 2 && is.null(degrees)) stop('Please specify a vector of angles that sum to 90')    
    theta <- seq(-4,4, length.out=40)
    Theta <- ThetaFull <- thetaComb(theta, nfact)   
    prodlist <- attr(x@pars, 'prodlist')
    if(length(prodlist) > 0)        
        ThetaFull <- prodterms(Theta,prodlist)
    P <- ProbTrace(x=x@pars[[item]], Theta=Theta)         
    info <- 0 
    if(nfact == 2){
        for(i in 1:length(degrees))
            info <- info + iteminfo(x=x@pars[[item]], Theta=ThetaFull, degrees=c(degrees[i], 
                                                                             90 - degrees[i]))
    } else {
        info <- iteminfo(x=x@pars[[item]], Theta=ThetaFull, degrees=0)
    }
    if(type == 'RETURN') return(data.frame(P=P, info=info, Theta=Theta))
    score <- matrix(0:(ncol(P) - 1), nrow(Theta), ncol(P), byrow = TRUE)
    score <- rowSums(score * P)
    if(class(x@pars[[item]]) %in% c('nominal', 'graded', 'rating')) 
        score <- score + 1     
    if(nfact == 1){
        if(type == 'trace'){            
            plot(Theta, P[,1], col = 1, type='l', main = paste('Item', item), 
                 ylab = expression(P(theta)), xlab = expression(theta), ylim = c(0,1), las = 1, 
                 ...)
            for(i in 2:ncol(P))
                lines(Theta, P[,i], col = i)                 
        }
        if(type == 'info'){            
            plot(Theta, info, col = 1, type='l', main = paste('Information for item', item), 
                 ylab = expression(I(theta)), xlab = expression(theta), las = 1)
        }
        if(type == 'score'){            
            plot(Theta, score, col = 1, type='l', main = paste('Expected score for item', item), 
                 ylab = expression(E(theta)), xlab = expression(theta), 
                 ylim = c(min(floor(score)),max(ceiling(score))), las = 1)            
        }
        if(type == 'infocontour') stop('Cannot draw contours for 1 factor models')        
    } else {
        plt <- data.frame(info = info, Theta1 = Theta[,1], Theta2 = Theta[,2])
        plt2 <- data.frame(P = P, Theta1 = Theta[,1], Theta2 = Theta[,2])
        colnames(plt2) <- c(paste("P", 1:ncol(P), sep=''), "Theta1", "Theta2")
        plt2 <- reshape(plt2, direction='long', varying = paste("P", 1:ncol(P), sep=''), v.names = 'P', 
                times = paste("P", 1:ncol(P), sep=''))
        colnames(plt) <- c("info", "Theta1", "Theta2")  
        plt$score <- score
        if(type == 'infocontour')												
            return(contourplot(info ~ Theta1 * Theta2, data = plt, 
                               main = paste("Item", item, "Information Contour"), xlab = expression(theta[1]), 
                               ylab = expression(theta[2]), ...))
        if(type == 'info')
            return(lattice::wireframe(info ~ Theta1 + Theta2, data = plt, main = paste("Item", item, "Information"), 
                             zlab=expression(I(theta)), xlab=expression(theta[1]), ylab=expression(theta[2]), 
                             scales = list(arrows = FALSE), colorkey = TRUE, drape = TRUE, ...))
        if(type == 'trace'){
            return(lattice::wireframe(P ~ Theta1 + Theta2, data = plt2, group = time, main = paste("Item", item, "Trace"), 
                             zlab=expression(P(theta)), xlab=expression(theta[1]), ylab=expression(theta[2]), 
                             scales = list(arrows = FALSE), colorkey = TRUE, drape = TRUE, ...))            
        } 
        if(type == 'score'){            
            return(lattice::wireframe(score ~ Theta1 + Theta2, data = plt, main = paste("Item", item, "Expected Score"), 
                                      zlab=expression(E(theta)), xlab=expression(theta[1]), ylab=expression(theta[2]), 
                                      zlim = c(min(floor(plt$score)), max(ceiling(plt$score))),scales = list(arrows = FALSE), 
                                      colorkey = TRUE, drape = TRUE, ...))
        }
    }    
}