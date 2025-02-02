# date:   2016-08-02
# likelihood, derivative and second derivative function of alpha parameter from blei paper
# Likelihood alpha
# alhpa: (vector) 1*K (K: topic number)
# var_gamma_list: (list) length, N (the documents number in a corpus), column number: K (K: topic number)

sim_docu <- function(k=10, v=50, n=100){
  wordindex <- diag(1,nrow = v)
  document <- wordindex[sample(1:v,n,replace = TRUE),]
  document
}
sim_para <- function(k=10,v=50){
  alpha <- runif(k)
  beta <- matrix(runif(k*v),nrow = k)
  rowSums_beta <- rowSums(beta)
  beta <- apply(beta,2,function(x) x/rowSums_beta)
  list(alpha=alpha,beta=beta)
}

vbinfer <- function(document,alpha, beta, n.iter=500, e=0.0001){
  N <- dim(document)[1]
  v <- dim(document)[2]
  k <- length(alpha)
  if(dim(beta)[1]!= k) stop("ERROR: nrow(beta) should equal length(alpha)!")
  if(dim(beta)[2]!= v) stop("ERROR: ncol(beta) should equal dim(docu)[2]!")
  var_gamma <- numeric(k)
  phi <- matrix(numeric(N*k),nrow = N)
  # initialize variational paras
  for(i in 1:k){
    var_gamma[i] <- alpha[i] + N/k
    for(j in 1:N){
      phi[j,i] <- 1/k
    }
  }
  # update variational paras
  oldll <- 0
  var_iter <- 1
  while(TRUE){
    for(i in 1:N){
      for(j in 1:k){
        wn <- which(document[i,] == 1) # wn index of n word of document
        phi[i,j] <- beta[j,wn]*exp(digamma(var_gamma[j])) # update phi[n,k]
      }
      phi[i,] <- phi[i,]/sum(phi[i,]) # normalize sum(phi[n,]) to 1
    }
    var_gamma <- 50/k + colSums(phi)
    var_iter <- var_iter + 1
    newll <- likelihood(document,alpha,beta,var_gamma,phi)
    if(var_iter > n.iter || abs(newll-oldll)<e){
      break
    }
    # cat("Iter",var_iter,":\told=",oldll,"\tnew=",newll,"\n",sep="")
    oldll <- newll
  }
 list(g=var_gamma,p=phi,ll=newll)
}

likelihood <- function(document,alpha,beta,var_gamma,phi){
  # not exactly the likelihood, but the lower bound of likelihood
  # var_gamma: 1*k; phi: n*k; document: n*v; beta: k*v; alpha: 1*k
  diga <- digamma(var_gamma)- digamma(sum(var_gamma))
  third <- 0
  for(n in 1:nrow(phi)){
    for(k in 1:ncol(phi)){
      third <- third + phi[n,k]*sum(document[n,]*log(beta[k,]))
    }
  }
  ll  <- lgamma(sum(alpha))-sum(lgamma(alpha)) + sum((alpha-1)*diga) + sum(phi %*% diga) + third - lgamma(sum(var_gamma)) + sum(lgamma(var_gamma))-sum((var_gamma-1)*diga) - sum(phi*log(phi))
  ll
}

e.step <- function(corpus,alpha, beta, n.iter=100, e=0.0001){
  # corpus: (list), set of document
  var_gamma_list <- list()
  phi_list <- list()
  ll_list <- list()
  for(i in 1:length(corpus)){
    document <- corpus[[i]]
    para <- vbinfer(document,alpha,beta)
    var_gamma_list[[i]] <- para$g
    phi_list[[i]] <- para$p
    ll_list[[i]] <- para$ll
  }
  list(g=var_gamma_list,p=phi_list,ll=ll_list)
}

m.step <- function(corpus, var_gamma_list, phi_list, ini.alpha, ini.beta, n.iter=100,e=0.0001){
  # var_gamma_list: M length list with each vector length as K
  # phi_list: M length list with each matrix dim as N * K
  # ini.alpha: 1 * K vector;
  # ini.beta: K * V matrix  
  
  # infer beta
  k <- dim(phi_list[[1]])[2]
  v <- dim(corpus[[1]])[2]
  beta <- ini.beta
  for(i in 1:k){
    for(j in 1:v){
      wd <- NULL
      phiarr <- NULL
      for(d in 1:length(corpus)){
        document <- corpus[[d]]
        phi <- phi_list[[d]]
        phiarr <- cbind(phiarr,phi[,i])
        wd <- cbind(wd,document[,j])
      }
      ele <- sum(diag(phiarr %*% t(wd)))
      beta[i,j] <- ele
    }
	beta[i,] <- beta[i,]/sum(beta[i,])
  }
  
  # Newton-Raphson method to get alpha
  # use object function of alpha, derivative, and second derivative function
  alpha <- ini.alpha
  for(i in 1:1000){
    alpha_new <- as.vector(alpha - solve(ddla(alpha)) %*% dla(alpha))
    # cat("#",i,"\n")
    # print(abs(sum(alpha_new-alpha)))
    if(abs(sum(alpha_new-alpha)) < e){
      break
    }
    alpha <- alpha_new
  }  
  # all likelihood
  ll <- 0
  for(i in 1:length(corpus)){
	ll <- ll + likelihood(corpus[[i]], alpha, beta, var_gamma_list[[i]], phi_list[[i]])
  }
  
  list(alpha=alpha,beta=beta,ll=ll)
}

# date:   2016-08-02
# likelihood, derivative and second derivative function of alpha parameter from blei paper
# Likelihood alpha
# alhpa: (vector) 1*K (K: topic number)
# var_gamma_list: (list) length, N (the documents number in a corpus), column number: K (K: topic number)

la <- function(alpha,g_list=var_gamma_list){
  M <- length(g_list)
  K <- length(alpha)
  g <- matrix(numeric(M*K),nrow = M)
  for(i in 1:M){
    for(j in 1:K){
      g[i,j] <- g_list[[i]][j]
    }
  }
  rowSums_g <- rowSums(g)
  g <- apply(g,2, function(x) digamma(x) - digamma(rowSums_g))
  for(i in 1:K){
    g[,i] <- (alpha[i] - 1) * g[,i]
  }
  l <- numeric(M)
  for(i in 1:M){
    l[i] <- lgamma(sum(alpha)) - sum(lgamma(alpha)) + sum(g[i,])
  }
  -sum(l)
}

dla <- function(alpha,g_list=var_gamma_list){
  M <- length(g_list)
  K <- length(alpha)
  g <- matrix(numeric(M*K),nrow = M)
  for(i in 1:M){
    for(j in 1:K){
      g[i,j] <- g_list[[i]][j]
    }
  }
  rowSums_g <- rowSums(g)
  g <- apply(g,2, function(x) digamma(x) - digamma(rowSums_g))
  jacobian <- numeric(K)
  for(i in 1:K){
    jacobian[i] <- M*(digamma(sum(alpha)) - digamma(alpha[i])) + sum(g[,i])
  }
  -jacobian
}

ddla <- function(alpha,g_list=var_gamma_list){
  k <- length(alpha)
  M <- length(g_list)
  hessian <- diag(0,k)
  for(i in 1:k){
    for(j in 1:k){
      if(i == j){
        hessian[i,j] <- 1*M*trigamma(alpha[i]) - M*trigamma(sum(alpha))
      }else{
        hessian[i,j] <- -M*trigamma(sum(alpha))
      }
    }
  }
  hessian
}