
# Josep Ll. Berral-García
# ALOJA-BSC-MSR hadoop.bsc.es
# 2015-01-14
# Implementation of Quadratic Regression Tree method recursive-partition-like

# Usage:
#	mtree <- qrt.tree(formula = target ~ .,dataset = dataframe);
#	prediction <- qrt.predict(model = mtree, newdata = dataframe);
#	qrt.plot.tree(mtree);

library(rpart);

###############################################################################
# Regression Tree M5-Prediction-like with Quadratic Regression                #
###############################################################################

qrt.tree <- function (formula, dataset, m = 30, cp = 0.001, simple = 0)
{
	if (!is.numeric(m)) m <- as.numeric(m);
	if (!is.numeric(cp)) cp <- as.numeric(cp);
	if (!is.numeric(simple)) simple <- as.numeric(simple);

	colnames(dataset) <- gsub(" ",".",colnames(dataset));

	vout <- get(as.character(formula[[2]]),envir=parent.frame());
	vin <- if (as.character(formula[[3]]) == ".") colnames(dataset)[(!colnames(dataset) %in% vout)] else as.character(formula[[3]]);

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

		mae <- mae + sum(abs(preds[[j]] - daux[,vout]));
		rae <- rae + sum(abs((preds[[j]] - daux[,vout])/daux[,vout]));
	}
	mae <- mae / nrow(dataset);
	rae <- rae / nrow(dataset);
	#print(paste("[INFO]", m , nrow(dataset),mae,rae,sep=" "));

	retval <- list();
	retval[["rpart"]] <- fit;
	retval[["regs"]] <- regs;
	retval[["indexes"]] <- indexes;
	retval[["mae"]] <- mae;
	retval[["rae"]] <- rae;

	err_data <- t(data.frame(strsplit(unlist(err_branch)," ")));
	auxid <- err_data[,1];
	err_data <- if (nrow(err_data)==1) t(data.frame(err_data[,-1])) else data.frame(err_data[,-1]);
	colnames(err_data) <- c("Instances","MAE","MAPE");
	rownames(err_data) <- auxid;

	retval[["error_branch"]] <- err_data;	

	preds <- unlist(preds);
	retval[["fitted.values"]] <- preds[order(as.integer(names(preds)))];

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
