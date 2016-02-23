
# Josep Ll. Berral-García
# ALOJA-BSC-MSR aloja.bsc.es
# 2016-02-20
# Implementation of Quadratic (or Linear) Regression Tree method recursive-partition-like

# Usage:
#	mtree <- qrt.tree(varout = target.name, dataset = dataframe, simple = 0);
#	prediction <- qrt.predict(model = mtree, newdata = dataframe);
#	qrt.plot.tree(mtree);

suppressMessages(library(rpart));	# Recursive Partition Trees

###############################################################################
# Regression Tree M5-Prediction-like with Linear/Quadratic Regression         #
###############################################################################

qrt.tree <- function (varout, dataset, m = 30, cp = 0.001, simple = 1)
{
	if (!is.numeric(m)) m <- as.numeric(m);
	if (!is.numeric(cp)) cp <- as.numeric(cp);
	if (!is.numeric(simple)) simple <- as.numeric(simple);

	vout <- varout;
	vin <- colnames(dataset)[(!colnames(dataset) %in% vout)];
	dataset <- dataset[,c(vout,vin)];

	fit <- rpart(formula=dataset[,vout]~.,data=dataset[,vin],method="anova",control=rpart.control(minsplit=as.integer(m),cp=as.numeric(cp)));
	nodes <- as.numeric(rownames(fit$frame));

	err_branch <- regs <- preds <- list();
	indexes <- NULL;
	mae <- rae <- 0;
	for (i in unique(fit$where))
	{
		daux <- dataset[fit$where==i,c(vout,vin)];
		j <- nodes[i];

		if (simple > 0) regs[[j]] <- lm(formula=daux[,vout] ~ ., data=data.frame(daux[,vin]));
		if (simple <= 0) regs[[j]] <- lm(formula=daux[,vout] ~ . + (.)^2, data=data.frame(daux[,vin]));
		indexes <- c(indexes,j);

		preds[[j]] <- regs[[j]]$fitted.values;
		err_branch[[j]] <- paste(j,nrow(daux),mean(abs(preds[[j]] - daux[,vout])),mean(abs((preds[[j]] - daux[,vout])/daux[,vout])),sep=" ");
	}

	retval <- list();
	retval[["rpart"]] <- fit;
	retval[["regs"]] <- regs;
	retval[["indexes"]] <- indexes;

	err_data <- data.frame(strsplit(unlist(err_branch)," "));
	err_data <- apply(err_data, 1, function(x) as.numeric(x));
	auxid <- if (is.null(nrow(err_data))) 1 else err_data[,1];
	err_data <- if (is.null(nrow(err_data))) t(data.frame(err_data[-1])) else data.frame(err_data[,-1]);
	colnames(err_data) <- c("Instances","MAE","MAPE");
	rownames(err_data) <- auxid;
	retval[["error_branch"]] <- err_data;	

	preds <- unlist(preds);
	retval[["fitted.values"]] <- preds[order(as.integer(names(preds)))];
	retval[["mae"]] <- mean(abs(retval$fitted.values - dataset[,vout]));
	retval[["rae"]] <- mean(abs((retval$fitted.values - dataset[,vout])/dataset[,vout]));

	class(retval) <- c(class(retval),"qrt");

	retval;
}

qrt.predict <- function (model, newdata)
{
	colnames(newdata) <- gsub(" ",".",colnames(newdata));

	fit_node <- model$rpart;
	fit_node$frame$yval <- as.numeric(rownames(fit_node$frame));

	sapply(1:nrow(newdata), function(i) {
		node <- as.numeric(predict(fit_node,newdata[i,]));
		pred <- as.numeric(predict(model$regs[[node]],newdata[i,]));
		pred;
	});
}

qrt.plot.tree <- function (model, uniform = TRUE, main = "Classification Tree", use.n = FALSE, all = FALSE)
{
	fit_node <- model$rpart;
	fit_node$frame$yval <- as.numeric(rownames(fit_node$frame));

	plot(fit_node,uniform=uniform,main=main);
	text(fit_node, use.n=use.n, all=all, cex=.8);
}

qrt.regressions <- function (model)
{
	retval <- list()
	for (i in sort(model$index)) retval[[paste("Reg-",i,sep="")]] <- model$regs[[i]]$coefficients[!is.na(model$regs[[i]]$coefficients)];
	retval;
}

qrt.regression.coefficients <- function (model, index)
{
	model$regs[[index]]$coefficients[!is.na(model$regs[[index]]$coefficients)];
}

qrt.regression.model <- function (model, index)
{
	model$regs[[index]]$model;
}

qrt.json <- function (model)
{
	faux <- model$rpart$frame;
	saux <- model$rpart$splits;
	spointer <- 1;

	jaux <- '';
	raux <- c(rownames(faux),1);

	for (i in 1:nrow(faux))
	{
		if (faux$var[i] == "<leaf>")
		{
			caux <- t(model$regs[[as.numeric(raux[i])]]$coefficients);
			eaux <- model$error_branch[raux[i],];
			laux <- '';
			for (j in 1:length(caux)) laux <- paste(laux,',"',colnames(caux)[j],'":"',caux[j],'"',sep="");
			laux <- paste('regression:{',substring(laux,2),'},mae:',eaux$MAE,',mape:',eaux$MAPE,sep="");

			jaux <- paste(jaux,'{text:{name:"',faux$var[i],'",desc:"',faux$n[i],':',faux$yval[i],'"},leaf:',raux[i],',n:',faux$n[i],',yval:',faux$yval[i],',',laux,'}',sep="");
			if (as.numeric(raux[i]) > as.numeric(raux[i+1]))
			{
				curr_level <- ceil(log(as.numeric(raux[i])+1)/log(2));
				next_level <- ceil(log(as.numeric(raux[i+1])+1)/log(2));
				for (j in 1:(curr_level - next_level)) jaux <- paste(jaux,']}',sep="");
			}
			if (i < nrow(faux)) jaux <- paste(jaux,',',sep="");
		}
		else
		{
			split <- saux[spointer,"index"];
			ineq <- saux[spointer,"ncat"];
			relation <- if (ineq == 1) paste('>=',split,sep="") else paste('<',split,sep="");
			spointer <- spointer + faux$ncompete[i] + faux$nsurrogate[i] + 1;

			jaux <- paste(jaux,'{text:{name: "',faux$var[i],relation,'",desc:"',faux$n[i],':',faux$yval[i],'"},var:"',faux$var[i],'",relation:',ineq,',split:',split,',leaf:',raux[i],',n:',faux$n[i],',yval:',faux$yval[i],',children:[',sep="");
		}
	}

	jaux;
}

###############################################################################
# Fine-tunning parameters for QRT                                             #
###############################################################################

qrt.select <- function (vout, vin, traux, tvaux, mintervals, quiet = 1, simple = 1, ...)
{
	trmae <- NULL;
	tvmae <- NULL;
	mmin <- 0;
	mminmae <- 9e+15;
	off_threshold <- 1e-4;
	for (i in mintervals)
	{
		ml <- qrt.tree(varout=vout,dataset=data.frame(traux[,c(vout,vin)]),m=i,simple=simple);
		trmae <- c(trmae, ml$mae);

		prediction <- qrt.predict(model=ml,newdata=data.frame(tvaux[,c(vout,vin)]));

		mae <- mean(abs(prediction - tvaux[,vout]));
		tvmae <- c(tvmae,mae);

		if (mae < mminmae - off_threshold) { mmin <- i; mminmae <- mae; }
		if (quiet == 0) print(paste("[INFO]",i,mae,mmin,mminmae));
	}
	if (quiet == 0) print (paste("Selected M:",mmin));	

	retval <- list();
	retval[["trmae"]] <- trmae;
	retval[["tvmae"]] <- tvmae;
	retval[["mmin"]] <- mmin;
	retval[["mintervals"]] <- mintervals;
	
	retval;
}


