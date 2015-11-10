
# Josep Ll. Berral-García
# ALOJA-BSC-MSRC hadoop.bsc.es
# 2015-03-09
# Heuristics and search library for ALOJA-ML

library("genalg");
library("FSelector");

###############################################################################
# Search algorithms based on heuristics                                       #
###############################################################################

gv_ref_model = NULL;
gv_ds_example = NULL;
gv_vin_simple = NULL;
gv_vin_complete = NULL;

aloja_genalg_search <- function (expression, vin, reference_model, vin_complete = NULL, iters = 20, mutation = 0.02)
{
	if (!is.numeric(mutation)) mutation <- as.numeric(mutation);
	if (!is.integer(iters)) iters <- as.integer(iters);

	dsex <- aloja_unfold_expression(expression,vin,reference_model);
	dsaux <- aloja_dbind(reference_model$dataset[,vin],dsex);
	dsaux <- aloja_binarize_ds(dsaux);	
	dsexb <- dsaux[(nrow(reference_model$dataset)+1):nrow(dsaux),];

	baseMin <- as.vector(sapply(colnames(dsexb),function(x) min(dsexb[,x])));
	baseMax <- as.vector(sapply(colnames(dsexb),function(x) max(dsexb[,x])));

	gv_ref_model <<- reference_model;
	gv_ds_example <<- dsexb;
	gv_vin_simple <<- vin;
	if (!is.null(vin_complete)) gv_vin_complete <<- vin_complete; # Ad_Hoc stuff for Aloja Clusters # TODO - Set the ones that miss from ref$varin from vin

	rbga.results <- rbga(baseMin, baseMax, evalFunc=aloja_genalg_evaluate, verbose=FALSE, mutationChance=mutation, iters=iters);

	binstance <- dsexb[0,];
	baux <- rbga.results$population[which(rbga.results$mean == min(rbga.results$mean)),];
	dummy <- ifelse (is.null(nrow(baux)), binstance[1,] <- baux, binstance[1,] <- baux[1,]);
	best_inst <- aloja_debinarize_instance(reference_model$dataset[,vin], vin, binstance);

	retval <- list();

	Prediction <- min(rbga.results$mean);
	retval[["best.inst"]] <- cbind(best_inst,Prediction);
	retval[["results"]] <- rbga.results;

	retval;
}

aloja_genalg_evaluate <- function (string=c())
{
	returnVal = NA;
	if (length(string) == ncol(gv_ds_example))
	{
		binstance <- gv_ds_example[0,];
		binstance[1,] <- string;
		dsdbin <- aloja_debinarize_instance(gv_ref_model$dataset[,gv_vin_simple], gv_vin_simple, binstance);
		viable <- all(!is.na(dsdbin));

		if (!is.null(gv_vin_complete)) # Ad_Hoc stuff for Aloja Clusters
		{
			extra <- (gv_ref_model$dataset[gv_ref_model$dataset$Cluster==dsdbin$Cluster,gv_vin_complete])[1,];
			dsdbin <- cbind(dsdbin,extra);
		}

		returnVal <- 9E15;
		if (viable) returnVal <- aloja_predict_instance(gv_ref_model,gv_ref_model$varin,dsdbin)[,"Prediction"];
	} else {
		stop(paste("Expecting a chromosome of length",ncol(gv_ds_example),"!",sep=" "));
	}
	returnVal;
}

###############################################################################
# Algorithms to decompose search results into Decision Trees                  #
###############################################################################

aloja_representative_tree <- function (vin, vout = "Prediction", method = "ordered", ds = NULL, predicted_instances = NULL, pred_file = NULL, dump_file = NULL, output = NULL, saveall = NULL, ...)
{
	if (is.null(ds))
	{
		if (is.null(predicted_instances))
		{
			if (is.null(pred_file) && is.null(dump_file)) return (NULL);
			if (!is.null(pred_file)) predicted_instances <- read.table(paste(pred_file,"-predictions.data",sep=""),sep=",",header=TRUE,stringsAsFactors=FALSE);
			if (!is.null(dump_file))
			{
				predicted_instances <- (read.table(dump_file,sep="",header=FALSE,stringsAsFactors=FALSE))[,c(2,3)];
				colnames(predicted_instances) <- c("Instance",vout);
			}
		}

		b <- sapply(predicted_instances$Instance,function(x) strsplit(x,","));
		b <- as.data.frame(t(matrix(unlist(b),nrow=length(vin))));
		b <- cbind(b,predicted_instances[,vout]);
		colnames(b) <- c(vin,vout);
	} else {
		b <- ds[,c(vin,vout)];
	}
	bord <- b[order(b[,vout]),];

	#daux <- rpart(Prediction ~., data = bord, parms=list(split='gini'));
	#daux <- rpart(Prediction ~., data = baux, control=rpart.control(minsplit = 2), parms=list(split='gini')); var1 <- rownames(daux$splits)[1];
	# eq: rpart(Prediction ~., data = bord, control=rpart.control(minsplit = 2), method = "class"); # This does the same that gini...

	gini_improvement <- function (ds, var1, target)
	{
		gini <- function(x, unbiased = FALSE)
		{
		    n <- length(x)
		    mu <- mean(x)
		    N <- if (unbiased) n * (n - 1) else n * n
		    ox <- x[order(x)];
		    dsum <- drop(crossprod(2 * 1:n - n - 1,  ox))
		    dsum / (mu * N)
		}
	
		impurities <- NULL;
		nobs <- NULL;
		for (i in levels(as.factor(ds[,var1])))
		{
			if (nrow(ds[ds[,var1]==i,]) > 0)
			{
				impurities <- c(impurities,gini(ds[ds[,var1]==i,target]));
				nobs <- c(nobs,nrow(ds[ds[,var1]==i,]));
			}
		}
		sum_nobs <- nrow(ds);

		impurity_root<- gini(ds[,target]);
		impurity_sum <- sum(sapply(1:length(impurities),function(x) impurities[x]*(nobs[x]/sum_nobs)));
		impurity_root - impurity_sum ;
	}
	
	attrib_search <- function (baux,level=0,method="ordered")
	{
		retval <- NULL;
		if (nrow(baux) > 1)
		{
			var1 <- NULL;
			if (method == "ordered") # Using "ordered changes" method
			{
				ns <- colnames(baux)[!colnames(baux) %in% "Prediction"];

				changes <- NULL;
				chnames <- NULL;
				for (i in ns)
				{
					change <- 0;
					for (j in 2:nrow(baux))
					{
						if (baux[j-1,i] != baux[j,i]) change <- change + 1;
					}
					if (change > 0)
					{
						changes <- c(changes,change);
						chnames <- c(chnames,i);
					}
				}
				if (!is.null(changes)) var1 <- chnames[(which(changes==min(changes)))[1]];

			} else if (method == "information") # Using information gain
			{
				daux <- information.gain(Prediction~., baux);
				var1 <- (rownames(daux)[which(daux==max(daux))])[1];

			} else if (method == "gini") # Using gini improvement
			{
				ns <- colnames(baux)[!colnames(baux) %in% "Prediction"];
				daux <- sapply(ns, function(x) gini_improvement(baux,x,"Prediction"));
				var1 <- (names(daux)[which(daux==max(daux))])[1];
			}

			if (!is.null(var1))
			{
				retval <- list();
				for (i in levels(baux[,var1])) # TODO - Executar en Ordre
				{
					bnext <- baux[baux[,var1]==i,];
					retaux <- attrib_search(bnext,level=level+1,method=method);

					if (!is.list(retaux)) # FIXME - R is.nan() can't handle lists... :(
					{
						if (!is.nan(retaux)) retval[[paste(var1,i,sep="=")]] <- retaux;
					} else retval[[paste(var1,i,sep="=")]] <- retaux;
				}
				if (length(retval) == 0) retval <- NaN;
			} else {
				retval <- round(mean(baux$Prediction));
			}
		} else {
			retval <- round(mean(baux$Prediction));
		}
		retval;
	}
	stree <- attrib_search(bord,method=method);
	ctree <- aloja_compress_tree(stree);

	retval <- ctree;
	if (!is.null(output) && output=="string") retval <- aloja_repress_tree_string (ctree);
	if (!is.null(output) && output=="ascii") retval <- aloja_repress_tree_ascii (ctree);
	if (!is.null(output) && output=="html") retval <- aloja_repress_tree_html (ctree);
	if (!is.null(output) && output=="nodejson") retval <- aloja_repress_tree_nodejson (ctree);

	if (!is.null(saveall))
	{
		write.table(retval, file = paste(saveall,"-reptree.data",sep=""));
	}

	retval;	
}

aloja_compress_tree <- function (stree, level = 0)
{
	retval <- list();
	for(i in names(stree))
	{
		if (is.numeric(stree[[i]]))
		{
			retval[[i]] <- stree[[i]];
		} else {
			retval[[i]] <- aloja_compress_tree(stree[[i]], level=level+1);
		}
	}

	names_list <- names(stree);
	for (i in names(stree))
	{
		for (j in names_list)
		{
			if (i != j && identical(retval[[i]],retval[[j]]))
			{
				aux <- retval[[i]];
				retval[[i]] <- NULL;
				retval[[j]] <- NULL;

				pattr <- sub("(.*)=.*","\\1",i);
				iattr <- sub(".*=(.*)","\\1",i);
				jattr <- sub(".*=(.*)","\\1",j);

				new_name <- paste(pattr,paste(iattr,jattr,sep="|"),sep="=");
				retval[[new_name]] <- aux;
				i <- new_name;

				names_list <- c(new_name,names_list);
				names_list <- names_list[-which(names_list==j)];
				names_list <- names_list[-which(names_list==i)];
			}
		}
	}
	retval;
}

aloja_repress_tree_string <- function (stree)
{
	if (!is.numeric(stree))
	{
		levelval <- '';
		for(i in names(stree))
		{
			plevelval <- aloja_repress_tree_string (stree[[i]]);
			if (levelval != '') levelval <- paste(levelval,",",sep="");
			levelval <- paste(levelval,i,":",plevelval,sep="");
		}
		retval <- paste("{",levelval,"}",sep="");
	} else {
		retval <- stree;
	}
	retval;
}

aloja_repress_tree_nodejson <- function (stree)
{
	if (!is.numeric(stree))
	{
		levelval <- '';
		for(i in names(stree))
		{
			plevelval <- aloja_repress_tree_nodejson (stree[[i]]);
			if (levelval != '') levelval <- paste(levelval,",",sep="");
			isplit <- unlist(strsplit(i,"="));
			levelval <- paste(levelval,'{text:{name: "',isplit[1],'",desc:"',isplit[2],'"},children:[',plevelval,']}',sep="");
		}
		retval <- levelval;
	} else {
		retval <- paste('{text:{name:"',stree,' seconds",desc:""}}',sep="");
	}
	retval;
}

aloja_repress_tree_ascii <- function (stree, level = 0)
{
	retval <- NULL;
	for(i in names(stree))
	{
		spaces <- paste(c(rep("  ",level),"*"),sep="",collapse="");
		icute <- str_replace(i,"="," : ");
		if (is.numeric(stree[[i]]))
		{
			retval <- c(retval,paste(spaces,icute,"->",mean(stree[[i]]),sep=" "));
		} else {
			retval <- c(retval,paste(spaces,icute,sep=" "));
			plevelval <- aloja_repress_tree_ascii (stree[[i]], level=level+1);
			retval <- c(retval,plevelval);
		}
	}

	if (level == 0) retval <- as.matrix(retval);
	retval;
}

aloja_repress_tree_html <- function (stree)
{
	if (!is.numeric(stree))
	{
		levelval <- '';
		for(i in names(stree))
		{
			plevelval <- aloja_repress_tree_html (stree[[i]]);
			if (levelval != '') levelval <- paste(levelval,"</li><li>",sep="");
			levelval <- paste(levelval,i,plevelval,sep="");
		}
		retval <- paste("<ul><li>",levelval,"</li></ul>",sep="");
	} else {
		retval <- paste(" &#8658; ",stree,sep="");
	}
	retval;
}
