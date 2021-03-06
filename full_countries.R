#full
library(devtools)
setwd('/Users/bomin8319/Desktop/DAME/DAME_pkg/R')
load_all()
load("/Users/bomin8319/Desktop/DAME/UNdatafull2.RData")
attach(UNdatafull)
library(FastGP)
library(mvtnorm)
library(fields)
library(reshape)
library(MCMCpack)
library(expm)
library(igraph)
library(DLFM2)
library(coda)
library(ggplot2)
library(LaplacesDemon)
library(truncnorm)
library(gridExtra)
ggplotColours <- function(n = 6, h = c(0, 360) + 15){
  if ((diff(h) %% 360) < 1) h[2] <- h[2] - 360/n
  hcl(h = (seq(h[1], h[2], length = n)), c = 100, l = 65)
}
number_ticks <- function(n) {function(limits) pretty(limits, n)}

# 97 country version
Time = 32
N = 97

# not existing countries -> all missing values imputed using model (biased)
avail1 = matrix(1, Time, N)
colnames(avail1) = colnames(UNdatafull$Y)
avail1[1:8, which(colnames(avail1) %in% c("ROK", "PRK"))] =0 #North and South Korea did not joined UN voting until 1990
avail1[1:9, which(colnames(avail1) %in% c("RUS"))] = 0 #RUS X variables not existed until 1991
avail1[13:21, which(colnames(avail1) %in% c("IRQ"))] = 0 #IRQ under sanction

#avail1[9:14, which(colnames(avail1) %in% c("IRQ"))] = 0 #Under the rule of Saddam, economic data were considered state secrets; thus, reliable data for the era was limited. (From 1990 until Saddam accepted the terms and conditions of UN Resolution 986 in 1996 the GDP in Iraq remained at less than 30 percent of the 1989 value.)

Degrees = vapply(1:Time, function(tp) {rowSums(Y[tp,,], na.rm = TRUE)}, rep(0, N))
corr = vapply(1:31, function(l) {cor(Degrees[1:(N*(Time - l))], Degrees[(1 + N*l):(N*Time)], use = "complete")}, 0)
plot(corr, type = 'l')

# secondDegrees = sapply(1:Time, function(tp) {rowSums(Y[tp,which(avail1[tp,]==1),which(avail1[tp,]==1)] %*% Y[tp,which(avail1[tp,]==1),which(avail1[tp,]==1)], na.rm = TRUE)})
# corr2 = vapply(1:31, function(l) {
	# a = unlist(secondDegrees[1:(Time - l)])
	# b = unlist(secondDegrees[(1 +l):Time])
	# lengthab = min(length(a), length(b))
	# cor(a[1:lengthab],b[1:lengthab] , use = "complete")}, 0)

# thirdDegrees = sapply(1:Time, function(tp) {rowSums(Y[tp,which(avail1[tp,]==1),which(avail1[tp,]==1)] %*% Y[tp,which(avail1[tp,]==1),which(avail1[tp,]==1)]%*% Y[tp,which(avail1[tp,]==1),which(avail1[tp,]==1)], na.rm = TRUE)})
# corr2 = vapply(1:31, function(l) {
	# a = unlist(thirdDegrees[1:(Time - l)])
	# b = unlist(thirdDegrees[(1 +l):Time])
	# lengthab = min(length(a), length(b))
	# cor(a[1:lengthab],b[1:lengthab] , use = "complete")}, 0)

setwd("/Users/bomin8319/Desktop")
UN = DAME_MH(Y[1:Time,,], X[1:Time,,,1:6], RE = c("additive", "multiplicative"), R = 2, avail = avail1, burn =500, nscan = 2500, odens = 5, sigma_Q = c(10,1,0.1,0.1,10,10))
save(UN, file = "UN_full.RData")
UN2 = DAME_MH(Y[1:Time,,], X[1:Time,,,1:6], RE = c("additive"), R = 2, avail = avail1, burn = 5000, nscan =25000, odens = 50)
save(UN2, file = "UN_full2.RData")
UN3 = DAME_MH(Y[1:Time,,], X[1:Time,,,1:6], RE = c(), R = 2, avail = avail1, burn = 5000, nscan = 25000, odens = 50)
save(UN3, file = "UN_full3.RData")
UN4 = DAME_MH(Y[1:Time,,], X[1:Time,,,1:6], RE = c("multiplicative"), R = 2, avail = avail1, burn = 5000, nscan =25000, odens = 50)
save(UN4, file = "UN_full4.RData")
load("UN_full.RData")
load("UN_full2.RData")
load("UN_full3.RData")
load("UN_full4.RData")


## side by side 
hi = factor(1983:2014)
hello = list()
hello2 = list()
hello3 = list()
hello4 = list()
hellonew = list()
mean = list()

n2 = 1
for	(n in 1:N){
	hello[[n]] = matrix(NA, nrow = 0, ncol = 3)
	mean[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	diag(Y[d,, ])= 0
	Y[d, which(avail1[d,]==0), ] = 0
	Y[d, , which(avail1[d,]==0)] = 0
	Y[d, , ][which(is.na(Y[d, , ]))] = 0	
	hello[[n]]  = rbind(hello[[n]], cbind(UN$Degree[[d]][,n2]/ rowSums(UN$Degree[[d]]), rep(hi[d], length(UN$Degree[[d]][,n2])), rep("DAME", length(UN$Degree[[d]][,n2]))))
	mean[[n]] = rbind(mean[[n]], c(rowSums(Y[d,,], na.rm=TRUE)[n2] / sum(Y[d,,], na.rm = TRUE), hi[d], "DAME"))
}
colnames(hello[[n]]) = c("Degree", "Year", "Model")
hello[[n]] = as.data.frame(hello[[n]])
hello[[n]]$Year = factor(sort(as.numeric(hello[[n]]$Year)), labels = c(1983:2014))

	hello2[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello2[[n]]  = rbind(hello2[[n]], cbind(UN2$Degree[[d]][,n2]/ rowSums(UN2$Degree[[d]]), rep(hi[d], length(UN2$Degree[[d]][,n2])), rep("AE", length(UN2$Degree[[d]][,n2]))))
	}
colnames(hello2[[n]]) = c("Degree", "Year", "Model")
hello2[[n]] = as.data.frame(hello2[[n]])
hello2[[n]]$Year = factor(sort(as.numeric(hello2[[n]]$Year)), labels = c(1983:2014))

hello3[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello3[[n]]  = rbind(hello3[[n]], cbind(UN3$Degree[[d]][,n2]/rowSums(UN3$Degree[[d]]), rep(hi[d], length(UN3$Degree[[d]][,n2])), rep("NO", length(UN3$Degree[[d]][,n2]))))
	}
colnames(hello3[[n]]) = c("Degree", "Year", "Model")
hello3[[n]] = as.data.frame(hello3[[n]])
hello3[[n]]$Year = factor(sort(as.numeric(hello3[[n]]$Year)), labels = c(1983:2014))

hello4[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello4[[n]]  = rbind(hello4[[n]], cbind(UN4$Degree[[d]][,n2]/ rowSums(UN4$Degree[[d]]), rep(hi[d], length(UN4$Degree[[d]][,n2])), rep("ME", length(UN4$Degree[[d]][,n2]))))
	}
colnames(hello4[[n]]) = c("Degree", "Year", "Model")
hello4[[n]] = as.data.frame(hello4[[n]])
hello4[[n]]$Year = factor(sort(as.numeric(hello4[[n]]$Year)), labels = c(1983:2014))


hellonew[[n]] = as.data.frame(rbind(hello[[n]], hello4[[n]], hello2[[n]], hello3[[n]]))
colnames(mean[[n]]) =  c("Degree", "Year", "Model")
mean[[n]] = as.data.frame(mean[[n]])
n2 = n2 + 1
}

countryname = (rownames(UN$U[[Time]]))
countryname2 = (rownames(UN$U[[Time]]))

setwd('/Users/bomin8319/Desktop/model_validation')
countrynames = ggplotColours(4)
p10 = list()
n2 = 1
for (n in 1:N){
	hellonew[[n]]$Degree = as.numeric(as.character(hellonew[[n]]$Degree))
	mean[[n]]$Degree = as.numeric(as.character(mean[[n]]$Degree))
	mean[[n]]$Year = hi
p10[[n]] = ggplot(hellonew[[n]], aes(x = Year, y = Degree, color= Model, fill =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() +scale_fill_manual(values = alpha(countrynames,0.5), name = countryname[n])+scale_color_manual(values = countrynames,name = countryname[n]) + geom_line(data = mean[[n]], color = "blue", size = 0.2, group = 1)+geom_point(data = mean[[n]], color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
#annotate("text", 30, 10, size = 5, label = countryname2[n], colour = countrynames[n])
n2 = n2 + 1

mname = paste0(countryname2[n], n, ".png")
print(p10[[n]])
ggsave(filename = mname, width = 12, height = 6)
}

#seconddegree
hi = factor(1983:2014)
hello = list()
hello2 = list()
hello3 = list()
hello4 = list()
hellonew = list()
mean = list()
countrynames = sort(rownames(UN$U[[Time]]))

n2 = 1
for 	(n in 1:N){
	hello[[n]] = matrix(NA, nrow = 0, ncol = 3)
	mean[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello[[n]]  = rbind(hello[[n]], cbind(UN$secondDegree[[d]][,n2]/rowSums(UN$secondDegree[[d]]), rep(hi[d], length(UN$secondDegree[[d]][,n2])), rep("DAME", length(UN$secondDegree[[d]][,n2]))))
	diag(Y[d,, ])= 0
	Y[d, which(avail1[d,]==0), ] = 0
	Y[d, , which(avail1[d,]==0)] = 0
	Y[d, , ][which(is.na(Y[d, , ]))] = 0
	mean[[n]] = rbind(mean[[n]], c(rowSums(Y[d,,] %*% Y[d,,], na.rm = TRUE)[n2]/ sum(Y[d,,] %*% Y[d,,], na.rm = TRUE), hi[d], "DAME"))
}
colnames(hello[[n]]) = c("SecondDegree", "Year", "Model")
hello[[n]] = as.data.frame(hello[[n]])
hello[[n]]$Year = factor(sort(as.numeric(hello[[n]]$Year)), labels = c(1983:2014))

	hello2[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello2[[n]]  = rbind(hello2[[n]], cbind(UN2$secondDegree[[d]][,n2]/rowSums(UN2$secondDegree[[d]]), rep(hi[d], length(UN2$secondDegree[[d]][,n2])), rep("AE", length(UN2$secondDegree[[d]][,n2]))))
	}
colnames(hello2[[n]]) = c("SecondDegree", "Year", "Model")
hello2[[n]] = as.data.frame(hello2[[n]])
hello2[[n]]$Year = factor(sort(as.numeric(hello2[[n]]$Year)), labels = c(1983:2014))

hello3[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello3[[n]]  = rbind(hello3[[n]], cbind(UN3$secondDegree[[d]][,n2]/rowSums(UN3$secondDegree[[d]]), rep(hi[d], length(UN3$secondDegree[[d]][,n2])), rep("NO", length(UN3$secondDegree[[d]][,n2]))))
	}
colnames(hello3[[n]]) = c("SecondDegree", "Year", "Model")
hello3[[n]] = as.data.frame(hello3[[n]])
hello3[[n]]$Year = factor(sort(as.numeric(hello3[[n]]$Year)), labels = c(1983:2014))

hello4[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello4[[n]]  = rbind(hello4[[n]], cbind(UN4$secondDegree[[d]][,n2]/rowSums(UN4$secondDegree[[d]]), rep(hi[d], length(UN4$secondDegree[[d]][,n2])), rep("ME", length(UN4$secondDegree[[d]][,n2]))))
	}
colnames(hello4[[n]]) = c("SecondDegree", "Year", "Model")
hello4[[n]] = as.data.frame(hello4[[n]])
hello4[[n]]$Year = factor(sort(as.numeric(hello4[[n]]$Year)), labels = c(1983:2014))

hellonew[[n]] = as.data.frame(rbind(hello[[n]],hello4[[n]], hello2[[n]], hello3[[n]]))
colnames(mean[[n]]) =  c("SecondDegree", "Year", "Model")
mean[[n]] = as.data.frame(mean[[n]])
n2 = n2 + 1
}

countryname = (rownames(UN$U[[Time]]))
countryname2 = (rownames(UN$U[[Time]]))
ggplotColours <- function(n = 6, h = c(0, 360) + 15){
  if ((diff(h) %% 360) < 1) h[2] <- h[2] - 360/n
  hcl(h = (seq(h[1], h[2], length = n)), c = 100, l = 65)
}
countrynames = ggplotColours(4)
p10 = list()
n2 = 1
for (n in 1:N){
	hellonew[[n]]$SecondDegree = as.numeric(as.character(hellonew[[n]]$SecondDegree))
	mean[[n]]$SecondDegree = as.numeric(as.character(mean[[n]]$SecondDegree))
	mean[[n]]$Year = hi
p10[[n]] = ggplot(hellonew[[n]], aes(x = Year, y = SecondDegree, color= Model, fill =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() +scale_fill_manual(values = alpha(countrynames,0.5), name = countryname[n])+scale_color_manual(values = countrynames,name = countryname[n]) + geom_line(data = mean[[n]], color = "blue", size = 0.2, group = 1)+geom_point(data = mean[[n]], color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())

#annotate("text", 30, 10, size = 5, label = countryname2[n], colour = countrynames[n])
n2 = n2 + 1

mname = paste0(countryname2[n], n, "second.png")
print(p10[[n]])
ggsave(filename = mname, width = 12, height = 6)
}


#thirddegree
hi = factor(1983:2014)
hello = list()
hello2 = list()
hello3 = list()
hello4 = list()
hellonew = list()
mean = list()
countrynames = sort(rownames(UN$U[[Time]]))

n2 = 1
for 	(n in 1:N){
	hello[[n]] = matrix(NA, nrow = 0, ncol = 3)
	mean[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello[[n]]  = rbind(hello[[n]], cbind(UN$thirdDegree[[d]][,n2]/rowSums(UN$thirdDegree[[d]]), rep(hi[d], length(UN$thirdDegree[[d]][,n2])), rep("DAME", length(UN$thirdDegree[[d]][,n2]))))
	diag(Y[d,, ])= 0
	Y[d, which(avail1[d,]==0), ] = 0
	Y[d, , which(avail1[d,]==0)] = 0
	Y[d, , ][which(is.na(Y[d, , ]))] = 0
	mean[[n]] = rbind(mean[[n]], c(rowSums(Y[d,,] %*% Y[d,,] %*% Y[d,,], na.rm = TRUE)[n2]/sum(Y[d,,] %*% Y[d,,] %*% Y[d,,], na.rm = TRUE), hi[d], "DAME"))
}
colnames(hello[[n]]) = c("ThirdDegree", "Year", "Model")
hello[[n]] = as.data.frame(hello[[n]])
hello[[n]]$Year = factor(sort(as.numeric(hello[[n]]$Year)), labels = c(1983:2014))

	hello2[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello2[[n]]  = rbind(hello2[[n]], cbind(UN2$thirdDegree[[d]][,n2]/rowSums(UN2$thirdDegree[[d]]), rep(hi[d], length(UN2$thirdDegree[[d]][,n2])), rep("AE", length(UN2$thirdDegree[[d]][,n2]))))
	}
colnames(hello2[[n]]) = c("ThirdDegree", "Year", "Model")
hello2[[n]] = as.data.frame(hello2[[n]])
hello2[[n]]$Year = factor(sort(as.numeric(hello2[[n]]$Year)), labels = c(1983:2014))

hello3[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello3[[n]]  = rbind(hello3[[n]], cbind(UN3$thirdDegree[[d]][,n2]/rowSums(UN3$thirdDegree[[d]]), rep(hi[d], length(UN3$thirdDegree[[d]][,n2])), rep("NO", length(UN3$thirdDegree[[d]][,n2]))))
	}
colnames(hello3[[n]]) = c("ThirdDegree", "Year", "Model")
hello3[[n]] = as.data.frame(hello3[[n]])
hello3[[n]]$Year = factor(sort(as.numeric(hello3[[n]]$Year)), labels = c(1983:2014))


hello4[[n]] = matrix(NA, nrow = 0, ncol = 3)
	for (d in 1:Time){
	hello4[[n]]  = rbind(hello4[[n]], cbind(UN4$thirdDegree[[d]][,n2]/rowSums(UN4$thirdDegree[[d]]), rep(hi[d], length(UN4$thirdDegree[[d]][,n2])), rep("ME", length(UN4$thirdDegree[[d]][,n2]))))
	}
colnames(hello4[[n]]) = c("ThirdDegree", "Year", "Model")
hello4[[n]] = as.data.frame(hello4[[n]])
hello4[[n]]$Year = factor(sort(as.numeric(hello4[[n]]$Year)), labels = c(1983:2014))


hellonew[[n]] = as.data.frame(rbind(hello[[n]], hello4[[n]], hello2[[n]], hello3[[n]]))
colnames(mean[[n]]) =  c("ThirdDegree", "Year", "Model")
mean[[n]] = as.data.frame(mean[[n]])
n2 = n2 + 1
}

countryname = (rownames(UN$U[[Time]]))
countryname2 = (rownames(UN$U[[Time]]))
ggplotColours <- function(n = 6, h = c(0, 360) + 15){
  if ((diff(h) %% 360) < 1) h[2] <- h[2] - 360/n
  hcl(h = (seq(h[1], h[2], length = n)), c = 100, l = 65)
}
countrynames = ggplotColours(4)
p10 = list()
n2 = 1
for (n in 1:N){
	hellonew[[n]]$ThirdDegree = as.numeric(as.character(hellonew[[n]]$ThirdDegree))
	mean[[n]]$ThirdDegree = as.numeric(as.character(mean[[n]]$ThirdDegree))
	mean[[n]]$Year = hi
p10[[n]] = ggplot(hellonew[[n]], aes(x = Year, y = ThirdDegree, color= Model, fill =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal() +scale_fill_manual(values = alpha(countrynames,0.5), name = countryname[n])+scale_color_manual(values = countrynames,name = countryname[n]) +  geom_line(data = mean[[n]], color = "blue", size = 0.2, group = 1)+geom_point(data = mean[[n]], color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())

#annotate("text", 30, 10, size = 5, label = countryname2[n], colour = countrynames[n])
n2 = n2 + 1

mname = paste0(countryname2[n], n, "third.png")
print(p10[[n]])
ggsave(filename = mname, width = 12, height = 6)
}



#beta
beta = lapply(1:Time, function(t){summary(mcmc(UN$BETA[[t]][1:500,]))[[2]]})
betas = list()
for (i in 1:6) {betas[[i]] = sapply(1:Time, function(t){beta[[t]][i,]})}
betacols= ggplotColours(6)
plots = list()
i= 1
years = c(1983:2014)
data = data.frame(cbind(years,t(betas[[i]])))
 colnames(data)[4] = "beta"
 f = ggplot(data, aes(x = years))
plots[[1]]=f + geom_line(aes(y = beta), colour=betacols[1]) + geom_ribbon(aes(ymin = X2.5., ymax = X97.5.), alpha = 0.1) + scale_x_continuous(breaks=number_ticks(8))+ylab("Intercept") + theme_minimal()

color =betacols[-1]
varname = c("log(distance)", "Polity", "Alliance", "Lower trade-to-GDP ratio", "Common Language")
for (i in 2:6){
years = c(1983:2014)
data = data.frame(cbind(years,t(betas[[i]])))
 colnames(data)[4] = "beta"
 f = ggplot(data, aes(x = years))
 
 plots[[i]] <- f + geom_line(aes(y = beta), colour=color[i-1]) + geom_ribbon(aes(ymin = X2.5., ymax = X97.5.), alpha = 0.1) + ylab(varname[i-1]) + scale_x_continuous(breaks=number_ticks(8)) + geom_hline(yintercept = 0) + theme_minimal()

 }
 marrangeGrob(plots[1:6], nrow = 2, ncol = 3, top = NULL)

#thetaplot
colors = sort(rownames(UN$U[[Time]]))
colors[which(colors == "GFR")] = "GMY"
rownames(UN$U[[Time]])[31] = "GMY"
	thetanew = t(sapply(1:Time, function(t){colMeans(UN$theta[[t]])}))
	colnames(thetanew) = colnames(avail1)
	orders = sapply(1:N, function(n){which(colors[n]== rownames(UN$U[[Time]]))})
	thetanew = thetanew[,orders]
	data3 = data.frame(years = years, theta = thetanew)
	colnames(data3)[-1] = colors
	data3new = melt(data3, id = "years")
	colnames(data3new)[3] = "theta"
	f <- ggplot(data3new, aes(years, theta, colour = variable, label = variable))
	f + geom_line(size = 0.2)+
geom_text(data = data3new[data3new$years=="1983", ], aes(label = variable), check_overlap = F, hjust = 1.3, vjust = 1, size =3, show.legend = F )+
geom_text(data = data3new[data3new$years=="2014", ], aes(label = variable), check_overlap = F, hjust = -0.3, vjust = 1, size =3, show.legend = F )+ scale_x_continuous(breaks=number_ticks(8)) + scale_colour_discrete(name = "countries") + theme_minimal()




#thetaplot_reduced
ggcolors = ggplotColours(21)
colors = sort(rownames(UN$U[[Time]])[which(rownames(UN$U[[Time]]) %in% c("USA", "CHN", "IND", "ROK","PRK","IRQ","RUS","GRG","UKR","UKG", "FRN", "GMY", "TUR", "JPN", "ISR", "SYR", "LEB", "SUD", "IRN", "AUL", "PAK", "EGY","AFG"))])
data4new = data3new[data3new$variable %in% c("USA", "CHN", "IND", "ROK","PRK","IRQ","RUS","GRG","UKR","UKG", "FRN", "GMY", "TUR", "JPN", "ISR", "SYR", "LEB", "SUD", "IRN", "AUL", "PAK", "EGY","AFG"),]

f <- ggplot(data4new, aes(years, theta, color = variable, label = variable))
f + geom_line(size = 0.5, aes(linetype =as.factor(c(sapply(c(6:1,5:1,5:1,5:1), function(x){rep(x, Time)})))))+geom_point(size =1, aes(shape =as.factor(c(sapply(c(1:6,1:5,1:5,1:5), function(x){rep(x, Time)})))))+ scale_x_continuous(breaks=number_ticks(8)) + theme_minimal() + 
  geom_text(data = data4new[data4new$years=="1983", ], aes(label = variable), check_overlap = T, hjust = 1.3, vjust = 1, size =3, show.legend = F )+
geom_text(data = data4new[data4new$years=="2014", ], aes(label = variable), check_overlap = T, hjust = -0.3, vjust = 1, size =3, show.legend = F )+
  scale_color_manual(values = ggplotColours(21), name = "countries")+scale_linetype(guide = FALSE)+scale_shape(guide = FALSE)+
  guides(colour = guide_legend(override.aes = list(shape = c(1:6,1:5,1:5,1:5), linetype = c(6:1,5:1,5:1,5:1)))) 

f <- ggplot(data4new, aes(years, theta, color = variable, label = variable))
f + geom_line( aes(linetype =as.factor(c(sapply(c(6:1,5:1,5:1,5:1), function(x){rep(x, Time)})))))+ scale_x_continuous(breaks=number_ticks(8)) + theme_minimal() + 
  geom_text(data = data4new[data4new$years=="1983", ], aes(label = variable), check_overlap = F, hjust = 1.3, vjust = 1, size =3, show.legend = F )+
  geom_text(data = data4new[data4new$years=="1988", ], aes(label = variable), check_overlap = F, hjust = 0, vjust = 1.2, size =3, show.legend = F )+
  geom_text(data = data4new[data4new$years=="2009", ], aes(label = variable), check_overlap = F, hjust = 0, vjust = 1.2, size =3, show.legend = F )+
  geom_text(data = data4new[data4new$years=="2014", ], aes(label = variable), check_overlap = F, hjust = -0.3, vjust = 1, size =3, show.legend = F )+
  scale_color_manual(values = ggplotColours(21), name = "countries")+scale_linetype(guide = FALSE)+scale_shape(guide = FALSE)+
  guides(colour = guide_legend(override.aes = list(linetype = c(6:1,5:1,5:1,5:1)))) 


#UD plots_full
setwd('/Users/bomin8319/Desktop/UDU')
years = c(1983:2014)

Xstar = matrix(0, nrow = N, ncol = 2)
rownames(Xstar) = sort(rownames(UN$U[[Time]]))
rownames(Xstar)[which(rownames(Xstar) == "GFR")] = "GMY"
Xstar[94, ]= c(0,1)
Xstar[48, ] = c(1,0)
#Xstar[19, ] = c(0, -1)
##Xstar[20, ] = c(0.5, 0.5)
#Xstar[11, ] = c(1, 0)
#Xstar[16,] =c(0.5, 1)
plots= list()
data2 = list()
colors = sort(rownames(Xstar))
for (t in 1:Time) {
UDmat = matrix(NA, N, 2)
rownames(UDmat) = colors
rownames(UN$U[[t]])[which(rownames(UN$U[[t]]) == "GFR")] = "GMY"
UDmat[which(rownames(UDmat) %in% names(UN$U[[t]][,1] * UN$D[[t]][1] )),1] =  UN$U[[t]][,1] * UN$D[[t]][1] 
UDmat[which(rownames(UDmat) %in% names(UN$U[[t]][,2] * UN$D[[t]][2] )),2] =  UN$U[[t]][,2] * UN$D[[t]][2]
UDmat[which(rownames(UDmat) %in% names(UN$U[[t]][,2] * UN$D[[t]][2] )),] = procrustes(UDmat[which(rownames(UDmat) %in% rownames(UN$U[[t]])),], Xstar[which(rownames(Xstar) %in% rownames(UN$U[[t]])),])$X.new
#UDmat = UDmat - UDmat[which(rownames(UDmat) =="USA"),]
data2[[t]] = data.frame(UDmat)
colnames(data2[[t]])[1:2] = c("r1", "r2")
Xstar = UDmat
Xstar[is.na(Xstar)] = rep(0, 2)
}
#rangex = summary(unlist(sapply(1:Time, function(t){data2[[t]][,1][!is.na(data2[[t]][,1])]})))
#rangey = summary(unlist(sapply(1:Time, function(t){data2[[t]][,2][!is.na(data2[[t]][,2])]})))

for (t in 1:Time) {
colors.t = colors[which(colors %in% rownames(UN$U[[t]]))]
p <- ggplot(data2[[t]], aes(x = r1, y = r2, colour = colors, label = rownames(data2[[t]])))

plots[[t]] = p+ geom_text(size = 5, show.legend = F, check_overlap = F)+ ggtitle(years[t]) + theme_minimal()+ theme(plot.title = element_text(hjust = 0.5)) + scale_x_continuous(breaks=number_ticks(3)) + scale_y_continuous(breaks=number_ticks(3))
mname = paste0("plot", t, "full.png")
print(plots[[t]])
ggsave(filename = mname)
}

#rangex = summary(unlist(sapply(c(4,8,12,16,20,24,28,Time), function(t){data2[[t]][,1][!is.na(data2[[t]][,1])]})))
#rangey = summary(unlist(sapply(c(4,8,12,16,20,24,28,Time), function(t){data2[[t]][,2][!is.na(data2[[t]][,2])]})))
for (t in c(4,8,12,16,20,24,28,Time)) {
colors.t = colors[which(colors %in% rownames(UN$U[[t]]))]
p <- ggplot(data2[[t]], aes(x = r1, y = r2, colour = colors, label = rownames(data2[[t]])))+ labs(x = "r = 1", y = "r = 2")


plots[[t]] = p+ geom_text(size = 2, show.legend = F, check_overlap =FALSE)+ ggtitle(years[t]) + theme_minimal()+ theme(plot.title = element_text(hjust = 0.5))  + scale_x_continuous(breaks=number_ticks(3)) + scale_y_continuous(breaks=number_ticks(3))
}
marrangeGrob(plots[c(4,8,12,16,20,24,28,Time)], nrow = 2, ncol = 4, top = NULL)

#UD plots_reduced
data3 = list()
for (t in 1:Time) {
    data3[[t]] = data2[[t]][rownames(data2[[t]]) %in% c("USA", "CHN", "IND", "ROK","PRK","IRQ","RUS","GRG","UKR","UKG", "FRN", "GMY", "TUR", "JPN", "ISR", "SYR", "LEB", "SUD", "IRN", "AUL", "PAK", "EGY","AFG"),]
}
plots= list()
colors = sort(rownames(data3[[1]]))
for (t in 1:Time) {
    colors.t = colors[which(colors %in% rownames(UN$U[[t]]))]
    p <- ggplot(data3[[t]], aes(x = r1, y = r2, colour = colors, label = rownames(data3[[t]])))
    
    plots[[t]] = p+ geom_text(size = 5, show.legend = F)+ ggtitle(years[t]) + theme_minimal()+ theme(plot.title = element_text(hjust = 0.5)) + scale_x_continuous(breaks=number_ticks(3)) + scale_y_continuous(breaks=number_ticks(3))
    mname = paste0("plot", t, "reduced.png")
    print(plots[[t]])
    ggsave(filename = mname)
}



#rangex = summary(unlist(sapply(c(4,8,12,16,20,24,28,Time), function(t){data2[[t]][,1][!is.na(data2[[t]][,1])]})))
#rangey = summary(unlist(sapply(c(4,8,12,16,20,24,28,Time), function(t){data2[[t]][,2][!is.na(data2[[t]][,2])]})))
for (t in c(4,8,12,16,20,24,28,Time)) {
colors.t = colors[which(colors %in% rownames(UN$U[[t]]))]
p <- ggplot(data3[[t]], aes(x = r1, y = r2, colour = colors, label = rownames(data3[[t]]))) + labs(x = "r = 1", y = "r = 2")

plots[[t]] = p+ geom_text(size = 3, show.legend = F)+ ggtitle(years[t]) + theme_minimal()+ theme(plot.title = element_text(hjust = 0.5))  + scale_x_continuous(breaks=number_ticks(3)) + scale_y_continuous(breaks=number_ticks(3))
}
marrangeGrob(plots[c(4,8,12,16,20,24,28,Time)], nrow = 2, ncol = 4, top = NULL)


#correlations
p = list()
cordata = data.frame(rbind(UN$corr[,1:3]), c(rep("DAME", 500)))
colnames(cordata) = c("Lag1", "Lag2", "Lag3", "Model")
p[[1]] = ggplot(cordata, aes(x = Lag1, fill = Model, color = Model)) + geom_histogram(position = "identity", alpha = 0.5) + geom_vline(aes(xintercept = vapply(1:1, function(l) {cor(Degrees[1:(N*(Time - l))], Degrees[(1 + N*l):(N*Time)], use = "complete")}, 0)), col = "blue", size = 1) +theme_minimal() +theme(legend.position = "bottom")
p[[2]] = ggplot(cordata, aes(x = Lag2, fill = Model, color = Model)) + geom_histogram(position = "identity", alpha = 0.5) + geom_vline(aes(xintercept = vapply(2:2, function(l) {cor(Degrees[1:(N*(Time - l))], Degrees[(1 + N*l):(N*Time)], use = "complete")}, 0)), col = "blue", size = 1)  + theme_minimal()
p[[3]] = ggplot(cordata, aes(x = Lag3, fill = Model, color = Model)) + geom_histogram(position = "identity", alpha = 0.5) + geom_vline(aes(xintercept = vapply(3:3, function(l) {cor(Degrees[1:(N*(Time - l))], Degrees[(1 + N*l):(N*Time)], use = "complete")}, 0)), col = "blue", size = 1) +theme_minimal()+ theme(legend.position = "top")
marrangeGrob(p[1:3], nrow = 1, ncol = 3, top = NULL)
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}

mylegend<-g_legend(p[[1]])
p3 <- grid.arrange(arrangeGrob(p[[1]] + theme(legend.position="none"),
                         p[[2]] + theme(legend.position="none"),
                         p[[3]] + theme(legend.position="none"), nrow=1),
             mylegend, heights=c(10, 1))



setwd('/Users/bomin8319/Desktop/external')

##Posterior predictive of degree
ggcolors = ggplotColours(3)
datacollapse = matrix(0, nrow = 112500, ncol = 3)
observedcollapse = matrix(0, 75, 3)
pp = list()
for (tp in 1:Time) {
	diag(Y[tp,,]) = 0
	Y[tp, which(avail1[tp, ]==0), ] = 0
	Y[tp, , which(avail1[tp, ]==0)] = 0
	Y[tp, , ][which(is.na(Y[tp, , ]))] = 0
		data = t(sapply(1:500, function(r){tabulate(round(UN$Degree[[tp]][r,]), 95)}))[,-1:-20]
	colnames(data) =  c(21:95)
	datamat = matrix(0, 500, 75)
	colnames(datamat) = c(21:95)
	for (i in 1:500) {
		datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	datamat1 = data.frame(Proportion = c(datamat), Degree = factor(c(sapply(c(21:95), function(k){rep(k, 500)}))), Model = as.factor("AME"))

	 data =  t(sapply(1:500, function(r){tabulate(round(UN4$Degree[[tp]][r,]), 95)}))[,-1:-20]
	colnames(data) =  c(21:95)
	datamat = matrix(0, 500, 75)
	 colnames(datamat) = c(21:95)
	 for (i in 1:500) {
		 datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	 }
	 datamat2 = rbind(datamat1, data.frame(Proportion = c(datamat), Degree = factor(c(sapply(c(21:95), function(k){rep(k, 500)}))), Model = as.factor("ME")))
		
	 data =  t(sapply(1:500, function(r){tabulate(round(UN2$Degree[[tp]][r,]), 95)}))[,-1:-20]
	 colnames(data) =  c(21:95)
	 datamat = matrix(0, 500,75)
	 colnames(datamat) = c(21:95)
		 for (i in 1:500) {
		 datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	 datamat3 = rbind(datamat2, data.frame(Proportion = c(datamat), Degree = factor(c(sapply(c(21:95), function(k){rep(k, 500)}))), Model = as.factor("AE")))
	
	 data =  t(sapply(1:500, function(r){tabulate(round(UN3$Degree[[tp]][r,]), 95)}))[,-1:-20]
	 colnames(data) =  c(21:95)
	 datamat = matrix(0, 500, 75)
	 colnames(datamat) =c(21:95)
		 for (i in 1:500) {
		 datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	 datamat4 = rbind(datamat3, data.frame(Proportion = c(datamat), Degree = factor(c(sapply(c(21:95), function(k){rep(k, 500)}))), Model = as.factor("NO")))
	datamat4 = datamat3
	datamat4 = as.data.frame(datamat4)
	observedpp = as.numeric(tabulate(round(rowSums(Y[tp,,])), 95) / sum(tabulate(round(rowSums(Y[tp,,])), 95)))[-1:-20]
	names(observedpp) = c(21:95)
	pvec = rep(0, 75)
	names(pvec) =c(21:95)
	pvec[which(names(pvec) %in% names(observedpp))] = observedpp
	observed = data.frame(Proportion = pvec, Degree = as.factor(c(21:95)), Model = "AME")
	pp[[tp]] = ggplot(datamat4, aes(x = Degree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observed, color = "blue", size = 0.2, group = 1)+geom_point(data =observed, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
    datacollapse[,1] = datacollapse[,1] + datamat3[,1]
    observedcollapse[,1] = observedcollapse[,1] + observed[,1]
}
years = c(1983:2014)
for (t in 1:Time){
mname = paste0(years[t], "overalldegree", ".png")
print(pp[[t]])
#ggsave(filename = mname, width = 10, height = 6)
}
datacollapse = data.frame(Proportion = datacollapse[,1]/Time, Degree = datamat3$Degree, Model = datamat3$Model)
observedcollapse = data.frame(Proportion = observedcollapse[,1]/Time, Degree = observed$Degree, Model = observed$Model)
datacollapse2 = datacollapse[datacollapse$Model == "AME",]
pp = ggplot(datacollapse, aes(x = Degree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
pp = ggplot(datacollapse2, aes(x = Degree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())

#seconddegree
ggcolors = ggplotColours(3)
datacollapse = matrix(0, nrow = 93000, ncol = 3)
observedcollapse = matrix(0, 62, 3)
pp = list()
for (tp in 1:Time) {
	diag(Y[tp,,]) = 0
	Y[tp, which(avail1[tp, ]==0), ] = 0
	Y[tp, , which(avail1[tp, ]==0)] = 0
	Y[tp, , ][which(is.na(Y[tp, , ]))] = 0
	data = t(sapply(1:500, function(r){tabulate(round(UN$secondDegree[[tp]][r,]/N), 77)}))[,-1:-15]
	colnames(data) =  c(16:77)
	datamat = matrix(0, 500,62)
	colnames(datamat) = c(16:77)
	for (i in 1:500) {
		datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	datamat1 = data.frame(Proportion = c(datamat), secondDegree = factor(c(sapply(c(16:77), function(k){rep(k, 500)}))), Model = as.factor("AME"))

	data =  t(sapply(1:500, function(r){tabulate(round(UN4$secondDegree[[tp]][r,]/N), 77)}))[,-1:-15]
	colnames(data) =  c(16:77)
	datamat = matrix(0, 500, 62)
	colnames(datamat) = c(16:77)
	for (i in 1:500) {
		datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	datamat2 = rbind(datamat1, data.frame(Proportion = c(datamat), secondDegree = factor(c(sapply(c(16:77), function(k){rep(k, 500)}))), Model = as.factor("ME")))
		
	data =  t(sapply(1:500, function(r){tabulate(round(UN2$secondDegree[[tp]][r,]/N), 77)}))[,-1:-15]
	colnames(data) = c(16:77)
	datamat = matrix(0, 500, 62)
	colnames(datamat) = c(16:77)
		for (i in 1:500) {
		datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	datamat3 = rbind(datamat2, data.frame(Proportion = c(datamat), secondDegree = factor(c(sapply(c(16:77), function(k){rep(k, 500)}))), Model = as.factor("AE")))
	
	 data =  t(sapply(1:500, function(r){tabulate(round(UN3$secondDegree[[tp]][r,]), 77)}))[,-1:-15]
 colnames(data) =  c(16:77)
	datamat = matrix(0, 500, 62)
	colnames(datamat) =c(16:77)
		 for (i in 1:500) {
		 datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
	}
	 datamat4 = rbind(datamat3, data.frame(Proportion = c(datamat), secondDegree = factor(c(sapply(c(16:77), function(k){rep(k, 500)}))), Model = as.factor("NO")))
	datamat4 = datamat3
	datamat4 = as.data.frame(datamat4)
	observedpp = as.numeric(tabulate(round(rowSums(Y[tp,,]%*% Y[tp,,]/N)), 77) / sum(tabulate(round(rowSums(Y[tp,,] %*% Y[tp,,] /N)), 77)))[-1:-15]
	names(observedpp) = c(16:77)
	pvec = rep(0,62)
	names(pvec) =c(16:77)
	pvec[which(names(pvec) %in% names(observedpp))] = observedpp
	observed = data.frame(Proportion = pvec, secondDegree = as.factor(c(16:77)), Model = "AME")
	pp[[tp]] = ggplot(datamat4, aes(x = secondDegree, y = Proportion,fill = Model, color = Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observed, color = "blue", size = 0.2, group = 1)+geom_point(data =observed, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
    datacollapse[,1] = datacollapse[,1] + datamat4[,1]
    observedcollapse[,1] = observedcollapse[,1] + observed[,1]
}

for (t in 1:Time){
mname = paste0(years[t], "overallseconddegree", ".png")
print(pp[[t]])
ggsave(filename = mname, width = 10, height = 6)
}

datacollapse = data.frame(Proportion = datacollapse[,1]/Time, secondDegree = datamat3$secondDegree, Model = datamat3$Model)
observedcollapse = data.frame(Proportion = observedcollapse[,1]/Time, secondDegree = observed$secondDegree, Model = observed$Model)
datacollapse2 = datacollapse[datacollapse$Model == "AME",]
pp = ggplot(datacollapse, aes(x = secondDegree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
pp = ggplot(datacollapse2, aes(x = secondDegree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())



#thirddegree
ggcolors = ggplotColours(3)
datacollapse = matrix(0, nrow = 82500, ncol = 3)
observedcollapse = matrix(0, 55, 3)

pp = list()
for (tp in 1:Time) {
    diag(Y[tp,,]) = 0
    Y[tp, which(avail1[tp, ]==0), ] = 0
    Y[tp, , which(avail1[tp, ]==0)] = 0
    Y[tp, , ][which(is.na(Y[tp, , ]))] = 0
    data = t(sapply(1:500, function(r){tabulate(round(UN$thirdDegree[[tp]][r,]/(N*N)), 66)}))[,-1:-11]
    colnames(data) =  c(12:66)
    datamat = matrix(0, 500, 55)
    colnames(datamat) = c(12:66)
    for (i in 1:500) {
        datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
    }
    datamat1 = data.frame(Proportion = c(datamat), thirdDegree = factor(c(sapply(c(12:66), function(k){rep(k, 500)}))), Model = as.factor("AME"))
    
    data =  t(sapply(1:500, function(r){tabulate(round(UN4$thirdDegree[[tp]][r,]/(N*N)), 66)}))[,-1:-11]
    colnames(data) =  c(12:66)
    datamat = matrix(0, 500, 55)
    colnames(datamat) = c(12:66)
    for (i in 1:500) {
        datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
    }
    datamat2 = rbind(datamat1, data.frame(Proportion = c(datamat), thirdDegree = factor(c(sapply(c(12:66), function(k){rep(k, 500)}))), Model = as.factor("ME")))
    
    data =  t(sapply(1:500, function(r){tabulate(round(UN2$thirdDegree[[tp]][r,]/(N*N)), 66)}))[,-1:-11]
    colnames(data) = c(12:66)
    datamat = matrix(0, 500, 55)
    colnames(datamat) = c(12:66)
    for (i in 1:500) {
        datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
    }
    datamat3 = rbind(datamat2, data.frame(Proportion = c(datamat), thirdDegree = factor(c(sapply(c(12:66), function(k){rep(k, 500)}))), Model = as.factor("AE")))
    
     data =  t(sapply(1:500, function(r){tabulate(round(UN3$thirdDegree[[tp]][r,]), 66)}))[,-1:-11]
    colnames(data) =  c(12:66)
    datamat = matrix(0, 500, 55)
     colnames(datamat) =c(12:66)
     for (i in 1:500) {
    datamat[i, which(colnames(datamat) %in% colnames(data))] = data[i,] / sum(data[i,])
     }
    datamat4 = rbind(datamat3, data.frame(Proportion = c(datamat), thirdDegree = factor(c(sapply(c(12:66), function(k){rep(k, 500)}))), Model = as.factor("NO")))
    datamat4 = datamat3
    datamat4 = as.data.frame(datamat4)
    observedpp = as.numeric(tabulate(round(rowSums(Y[tp,,]%*% Y[tp,,]%*% Y[tp,,]/(N*N))), 66) / sum(tabulate(round(rowSums(Y[tp,,] %*% Y[tp,,]%*% Y[tp,,] /(N*N))), 66)))[-1:-11]
    names(observedpp) = c(12:66)
    pvec = rep(0, 55)
    names(pvec) =c(12:66)
    pvec[which(names(pvec) %in% names(observedpp))] = observedpp
    observed = data.frame(Proportion = pvec, thirdDegree = as.factor(c(12:66)), Model = "AME")
    pp[[tp]] = ggplot(datamat4, aes(x = thirdDegree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observed, color = "blue", size = 0.2, group = 1)+geom_point(data =observed, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
    datacollapse[,1] = datacollapse[,1] + datamat4[,1]
    observedcollapse[,1] = observedcollapse[,1] + observed[,1]
}
years = c(1983:2014)
for (t in 1:Time){
    mname = paste0(years[t], "overallthirddegree", ".png")
    print(pp[[t]])
    ggsave(filename = mname, width = 10, height = 6)
}


datacollapse = data.frame(Proportion = datacollapse[,1]/Time, thirdDegree = datamat3$thirdDegree, Model = datamat3$Model)
observedcollapse = data.frame(Proportion = observedcollapse[,1]/Time, thirdDegree = observed$thirdDegree, Model = observed$Model)
pp = ggplot(datacollapse, aes(x = thirdDegree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
datacollapse2 = datacollapse[datacollapse$Model == "AME",]
pp = ggplot(datacollapse2, aes(x = thirdDegree, y = Proportion,fill = Model, color =Model)) + geom_boxplot(outlier.size = 0.5, position = position_dodge()) + theme_minimal()+scale_fill_manual(values = alpha(ggcolors, 0.5)) + geom_line(data = observedcollapse, color = "blue", size = 0.2, group = 1)+geom_point(data =observedcollapse, color = "blue", size =2, group = 1)+guides(colour = guide_legend(override.aes = list(shape = NA))) + theme(legend.title = element_blank())
