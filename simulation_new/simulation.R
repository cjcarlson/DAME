
#simulation 1
library(devtools)
setwd('/Users/bomin8319/Desktop/DAME/pkg/R')
load_all()
library(fields)
library(matrixStats)
library(mvtnorm)
library(FastGP)
library(LaplacesDemon)
library(MCMCpack)
library(DLFM2)
library(coda)
library(ggplot2)
library(gridExtra)

nsim = 1


# simulation 2
kappas = rep(0.001, 4)
Time = 10
N = 20
R = 2
dist_ij = c()
 for (i in 1:Time) {
 for (j in 1:Time) {
 dist_ij = c(dist_ij, abs(i-j))
 }
 }
dist_ij = matrix(dist_ij, Time, Time)
BETA = lapply(1:4, function(m){matrix(0, 1, Time)})
THETA = lapply(1:4, function(m){matrix(0, N, Time)})
UDUstat = lapply(1:4, function(m){matrix(0, 2, Time)})
Error = rep(0, 5)
Error2 = rep(0, 5)
Error3 = rep(0, 5)
Error4 = rep(0, 5)
Kappa = rep(0, 3)

for (s in 1:nsim){
print(s)
set.seed(s+2)
    tau_p = 1/rgamma(1, 2, 1)
    tau_i = 1/rgamma(1, 2, 1)
    tau_r = 1/rgamma(2,2,1)
    #tau_u = matrix(1/rgamma(Time*R, 2, 1), Time, R)
	tau_u = matrix(1, Time, R)
	beta = sapply(1:1, function(p){rmvnorm(1, rep(0, Time), tau_p * matrix(Exponential(dist_ij, kappas[p]), Time, Time, byrow = TRUE))})
	theta = sapply(1:N, function(i){rmvnorm(1, rep(0, Time), tau_i * matrix(Exponential(dist_ij, kappas[2]), Time, Time, byrow = TRUE))}) 
	U1 = sapply(1:N, function(i){rmvnorm(1, rep(0, Time), tau_u[,1]*diag(Time))}) 
	U2 = sapply(1:N, function(i){rmvnorm(1, rep(0, Time), tau_u[,2]*diag(Time))})
	U = lapply(1:Time , function(tp){cbind(U1[tp,], U2[tp,])})
	D = sapply(1:2, function(r){(-1)^1*rep(2, Time)})
	#while (sum(c(D) > 0) > 0) {
	#  D = sapply(1:2, function(r){rmvnorm(1, rep(-1, Time), tau_r[r] * matrix(Exponential(dist_ij, kappas[3]), Time, Time, byrow = TRUE))})
	#}
	s2 = 1 / rgamma(1, 2, 1)
	U2= array(0, dim = c(Time, N, R))
    for (tp in 1:Time) { U2[tp, , ] = U[[tp]]}
	UDU = lapply(1:Time , function(tp){U[[tp]] %*% diag(D[tp,]) %*% t(U[[tp]])})
	UDUstats = t(sapply(1:Time , function(tp){c(sum(UDU[[tp]][upper.tri(UDU[[tp]])]), sd(UDU[[tp]][upper.tri(UDU[[tp]])]))}))
	Ys = array(NA, dim = c(Time , N, N))
	Errormat = array(0, dim = c(Time, N, N))
	errors = rnorm(Time * N * (N-1) / 2, 0, sqrt(s2))
	for (tp in 1:Time) {
	  Errormat[tp, , ][upper.tri(Errormat[tp, , ])] = errors[((tp-1)*N*(N-1)/2+1):(tp*N*(N-1)/2)]
	  Errormat[tp, , ] = (Errormat[tp, , ] + t(Errormat[tp, , ]))
	Ys[tp, , ] = Reduce("+", lapply(1:1, function(p) {
                    1 * beta[tp, p]
                  })) + outer(theta[tp, ], theta[tp, ], "+") + UDU[[tp]] + Errormat[tp,,]
	diag(Ys[tp,,]) = 0   
	}	
Xnew = array(1, dim = c(Time , N, N, 1))
set.seed(s)
M1 = DLFM_fix(Ys, Xnew, RE = c("additive", "multiplicative"), gammapriors = c(2, 1), dist = "Exponential", avail = matrix(1, Time , N), R =2, burn = 400, nscan = 2000, odens = 4,kappas = rep(0.001, 4))

set.seed(s)
M3 = DLFM_Dunson_fixed(Ys, Xnew, RE = c("additive", "multiplicative"), gammapriors = c(2, 1), dist = "Exponential", avail = matrix(1, Time , N), R =2, burn = 400, nscan = 2000, odens = 4, kappas = rep(0.001, 4))

}
Degrees = vapply(1:Time, function(tp) {rowSums(Ys[tp,,])}, rep(0, N))
ggplotColours <- function(n = 6, h = c(0, 360) + 15){
  if ((diff(h) %% 360) < 1) h[2] <- h[2] - 360/n
  hcl(h = (seq(h[1], h[2], length = n)), c = 100, l = 65)
}
ggplotColours(2)

q = list()
for (i in 1:N) {
	M1_degree = lapply(1:Time, function(tp) {M1$Degree[[tp]][,i]})
	M3_degree = lapply(1:Time, function(tp) {M3$Degree[[tp]][,i]})
	q_degree = data.frame(c(unlist(M1_degree), unlist(M3_degree)), as.factor(c(vapply(1:Time, function(tp) {rep(tp, 500)}, rep(0, 500)))), as.factor(c(rep("UDU", 5000), rep("UU", 5000))))
	q_degree$observed = c(vapply(1:Time, function(tp) {rep(Degrees[i, tp], 500)}, rep(0, 500)))
	colnames(q_degree) = c("Degree", "Time", "Model", "Observed")
	q[[i]] = ggplot(q_degree, aes(x = Time, y = Degree, fill= Model,color= Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() + scale_color_manual(values = c("#F8766D" ,"#00BFC4", "blue")) + scale_fill_manual(values = alpha(c("#F8766D" ,"#00BFC4"), 0.5)) + geom_point(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 2, group = 1)+geom_line(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 0.2, group = 1)+theme(legend.position = "bottom", legend.title = element_blank())+guides(colour = guide_legend(override.aes = list(shape = NA)))
}

secondDegrees = vapply(1:Time, function(tp) {rowSums(Ys[tp,,] %*% Ys[tp,,])}, rep(0, N))
q2 = list()
for (i in 1:N) {
	M1_degree = lapply(1:Time, function(tp) {M1$secondDegree[[tp]][,i]})
	M3_degree = lapply(1:Time, function(tp) {M3$secondDegree[[tp]][,i]})
	q_degree = data.frame(c(unlist(M1_degree), unlist(M3_degree)), as.factor(c(vapply(1:Time, function(tp) {rep(tp, 500)}, rep(0, 500)))), as.factor(c(rep("UDU", 5000), rep("UU", 5000))))
	q_degree$observed = c(vapply(1:Time, function(tp) {rep(secondDegrees[i, tp], 500)}, rep(0, 500)))
	colnames(q_degree) = c("SecondDegree", "Time", "Model", "Observed")
	q2[[i]] = ggplot(q_degree, aes(x = Time, y = SecondDegree, fill= Model,color= Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() + scale_color_manual(values = c("#F8766D" ,"#00BFC4", "blue")) + scale_fill_manual(values = alpha(c("#F8766D" ,"#00BFC4"), 0.5)) + geom_point(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 2, group = 1)+geom_line(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 0.2, group = 1)
}

thirdDegrees = vapply(1:Time, function(tp) {rowSums(Ys[tp,,] %*% Ys[tp,,]%*% Ys[tp,,])}, rep(0, N))
q3 = list()
for (i in 1:N) {
	M1_degree = lapply(1:Time, function(tp) {M1$thirdDegree[[tp]][,i]})
	M3_degree = lapply(1:Time, function(tp) {M3$thirdDegree[[tp]][,i]})
	q_degree = data.frame(c(unlist(M1_degree), unlist(M3_degree)), as.factor(c(vapply(1:Time, function(tp) {rep(tp, 500)}, rep(0, 500)))), as.factor(c(rep("UDU", 5000), rep("UU", 5000))))
	q_degree$observed = c(vapply(1:Time, function(tp) {rep(thirdDegrees[i, tp], 500)}, rep(0, 500)))
	colnames(q_degree) = c("ThirdDegree", "Time", "Model", "Observed")
	q3[[i]] = ggplot(q_degree, aes(x = Time, y = ThirdDegree, fill= Model,color= Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() + scale_color_manual(values = c("#F8766D","#00BFC4", "blue")) + scale_fill_manual(values = alpha(c("#F8766D" ,"#00BFC4"), 0.5)) + geom_point(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 2, group = 1)+geom_line(data = q_degree, aes(x = Time, y = Observed), color = "blue", size = 0.2, group = 1)
}

g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}

mylegend<-g_legend(q[[1]])
p3 <- grid.arrange(arrangeGrob(q[[2]] + theme(legend.position="none"),
                         q2[[2]] + theme(legend.position="none"),
                         q3[[2]] + theme(legend.position="none"), nrow=1),mylegend,
             heights=c(10, 1))
             
             
  par(mfrow = c(2,5))           
 for (t in 1:10) {
 	plot(M3$theta[[t]][,10], type = 'l')
 	abline(h=theta[t,10], col = 'red')
 }            
sapply(1:10, function(t) cor(c(UDU[[t]][upper.tri(UDU[[t]])]), c(M1$UDU[[t]][upper.tri(UDU[[t]])])))             
sapply(1:10, function(t) cor(c(UDU[[t]][upper.tri(UDU[[t]])]), c(M3$UDU[[t]][upper.tri(UDU[[t]])])))             
             
             