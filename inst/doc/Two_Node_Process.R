## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(BayesMassBal)

## ----multiprocess, echo = FALSE, fig.height= 1.5, fig.width = 3---------------

yshift <- 1

rekt <- data.frame(matrix(NA, ncol = 4, nrow = 2))
names(rekt) <- c("xleft", "ybottom", "xright", "ytop")
rekt$xleft <- c(3,7)
rekt$ybottom <- 4
rekt$xright <- c(5,9)
rekt$ytop <- 6

aros <- data.frame(matrix(NA, ncol = 4, nrow = 5))
names(aros) <-c("x0","y0","x1","y1")
aros[1,] <- c(1,5,rekt$xleft[1],5)
aros[2,] <- c(rekt$xright[1],5,rekt$xleft[2],5)
aros[3,] <- c(rekt$xright[2],5,11,5)
aros[4,] <- c(rekt$xright[1] - 1, rekt$ybottom[1],rekt$xright[1] - 1, rekt$ybottom[1] - 2)
aros[5,] <- c(rekt$xright[2] - 1, rekt$ybottom[2], rekt$xright[2] - 1 , rekt$ybottom[2] - 2)

aros$y0 <- aros$y0
aros$y1 <- aros$y1

b.loc <- data.frame(matrix(NA, ncol = 2, nrow = 5))
names(b.loc) <- c("x","y")
b.loc[1,] <- c(0.5,aros$y0[1])
b.loc[2,] <- c(mean(c(aros$x0[2],aros$x1[2])),aros$y0[2] + 0.6)
b.loc[3,] <- c(aros$x1[3] + 0.5, aros$y1[3])
b.loc[4,] <- c(aros$x1[4], aros$y1[4] - 0.6)
b.loc[5,] <- c(aros$x1[5], aros$y1[5] - 0.6)

p.loc <- data.frame(matrix(NA, ncol = 2, nrow = 2))
names(p.loc) <- c("x","y")

p.loc$x <- rekt$xleft + 1
p.loc$y <- rekt$ybottom + 1

par(mar = c(0.1,0.1,0.1,0.1))
plot(1, type="n", xlab="", ylab="", xlim=c(0, 12), ylim=c(1, 6), axes = FALSE)
rect(xleft = rekt$xleft, ybottom = rekt$ybottom, xright = rekt$xright, ytop =rekt$ytop, col = "skyblue")
arrows(aros$x0,aros$y0, x1= aros$x1,y1 = aros$y1, code = 2, length = 0.1)
for(i in 1:5){
  text(b.loc$x[i], b.loc$y[i],labels = bquote(y[.(i)]), adj = c(0.5,0.5), cex = 1.2)
}
for(i in 1:2){
  text(p.loc$x[i], p.loc$y[i], labels = bquote(P[.(i)]), adj = c(0.5,0.5), cex = 1.2)
}
text(1.5,4.6,labels=  "F", adj = c(0.5,0.5), cex = 0.7)
text(c(5.5,9.5),c(4.6,4.6), labels = "C", adj= c(0.5,0.5), cex = 0.7)
text(c(4.4,8.4),c(3.5,3.5), labels = "T", adj= c(0.5,0.5), cex = 0.7)

## ----cdef---------------------------------------------------------------------
C <- matrix(c(1,-1,0,-1,0,0,1,-1,0,-1), nrow = 2, ncol = 5, byrow = TRUE)
C

## ----Xdef---------------------------------------------------------------------
X <- constrainProcess(C = C)
X

## ----Xdefcsv------------------------------------------------------------------
constraint_file_location <- system.file("extdata", "twonode_constraints.csv",package = "BayesMassBal")
X <- constrainProcess(file = constraint_file_location)

## ----datasim------------------------------------------------------------------
y <- importObservations(file = system.file("extdata", "twonode_example.csv",
                                  package = "BayesMassBal"),
                  header = TRUE, csv.params = list(sep = ";"))

## ----indepsamp----------------------------------------------------------------
indep.samples <- BMB(X = X, y = y, cov.structure = "indep", BTE = c(100,3000,1), lml = TRUE, verb = 0)

## ----feedplot-----------------------------------------------------------------

plot(indep.samples,sample.params = list(ybal = list(CuFeS2 = 3)),
    layout = "dens",hdi.params = c(1,0.95))

## ----traceplot----------------------------------------------------------------
plot(indep.samples,sample.params = list(beta = list(CuFeS2 = 1:3, gangue = 1:3)),layout = "trace",hdi.params = c(1,0.95))

## ----diagnostics--------------------------------------------------------------
indep.samples$diagnostics

## ----compdraw-----------------------------------------------------------------
component.samples <- BMB(X = X, y = y, cov.structure = "component", BTE = c(100,3000,1), lml = TRUE, verb = 0)


## ----locdraw------------------------------------------------------------------
location.samples <- BMB(X = X, y = y, cov.structure = "location", BTE = c(100,3000,1), lml = TRUE, verb = 0)

## ----compvsindep--------------------------------------------------------------
indep.samples$lml - component.samples$lml

## ----compvsloc----------------------------------------------------------------
component.samples$lml - location.samples$lml

## ----bayessummary-------------------------------------------------------------
summary(component.samples, export = NA)

## ----maineff------------------------------------------------------------------
fn_example <- function(X,ybal){
      cu.frac <- 63.546/183.5
      feed.mass <- ybal$CuFeS2[1] + ybal$gangue[1]
      # Concentrate mass per ton feed
      con.mass <- (ybal$CuFeS2[3] + ybal$gangue[3])/feed.mass
      # Copper mass per ton feed
      cu.mass <- (ybal$CuFeS2[3]*cu.frac)/feed.mass
      gam <- c(-1,-1/feed.mass,cu.mass,-con.mass,-cu.mass,-con.mass)
      f <- X %*% gam
      return(f)
      }

rangex <- matrix(c(4.00 ,6.25,1125,1875,3880,9080,20,60,96,208,20.0,62.5),
                   ncol = 6, nrow = 2)
mE_example <- mainEff(indep.samples, fn = "fn_example",rangex =  rangex,xj = 3, N = 25, res = 25)

## ----maineffplot--------------------------------------------------------------
m.sens<- mE_example$fn.out[2,]
hpd.sens <- mE_example$fn.out[c(1,3),]
row.names(hpd.sens) <- c("upper", "lower")
g.plot <- mE_example$g/2000

y.lim <- range(hpd.sens)

lzero.bound <- apply(hpd.sens,1,function(X){which(X <= 0)})
lzero.mean <- which(m.sens <= 0)

main.grid <- pretty(g.plot)
minor.grid <- pretty(g.plot,25)
minor.grid <- minor.grid[-which(minor.grid %in% main.grid)]

y.main <- pretty(hpd.sens)

opar <- par(no.readonly =TRUE) 
par(mar = c(4.2,4,1,1))
plot(g.plot,m.sens, type = "n", xlim = range(g.plot), ylim = y.lim, ylab = "Net Revenue ($/ton Feed)", xlab=  "Cu Price ($/lb)")

abline(v = main.grid, lty = 6, col = "grey", lwd = 1)
abline(v = minor.grid, lty =3, col = "grey", lwd = 0.75)

abline(h = 0, col = "red", lwd = 1, lty = 6)

lines(g.plot[lzero.mean],m.sens[lzero.mean],col = "red", lwd =2)
lines(g.plot[-lzero.mean[-length(lzero.mean)]],m.sens[-lzero.mean[-length(lzero.mean)]],col = "darkgreen", lwd =2)

lines(g.plot[lzero.bound$lower],hpd.sens[2,][lzero.bound$lower], lty = 5, lwd = 2, col = "red")
lines(g.plot[-lzero.bound$lower],hpd.sens[2,][-lzero.bound$lower], lty = 5, lwd = 2, col = "darkgreen")

lines(g.plot[lzero.bound$upper],hpd.sens[1,][lzero.bound$upper], lty = 5, lwd = 2, col = "red")
lines(g.plot[-lzero.bound$upper],hpd.sens[1,][-lzero.bound$upper], lty = 5, lwd = 2, col= "darkgreen")

legend("topleft", legend = c("Expected Main Effect", "95% Bounds", "Net Revenue < $0", "Net Revenue > $0"), col = c("black","black","red", "darkgreen"), lty = c(1,6,1,1), lwd = c(2,2,2,2), bg = "white")

par(opar)

