# Josep Ll. Berral-García
# ALOJA-BSC-MSR hadoop.bsc.es
# 2015-11-17
# Variable relation functions library for ALOJA-ML

library(rms);

## EXAMPLES
#
#vin <- c("Net","Disk","Maps","IO.SFac","IO.FBuf","Blk.size","Datanodes","VM.Cores","VM.RAM");
#vout <- "Exe.Time";
#
#ds <- aloja_get_data("test3-CL21-22.csv");
#aloja_variable_relations (ds, vin, vout, minsamples = 100);
#
#ds <- aloja_get_data("test4-CL21.csv");
#aloja_variable_relations (ds, vin, vout, minsamples = 100);

###############################################################################
# Variable relation tools                                                     #
###############################################################################

aloja_variable_relations <- function (ds, vin, vout, minsamples = 100, saveall = NULL, quiet = 1)
{
	if (!is.numeric(minsamples)) minsamples <- as.numeric(minsamples);

	retval <- list();

	for (i in vin)
	{
		retobj <- list();

		if (length(unique(ds[,i])) < 2)
		{
			if (quiet == 0) print(paste("Exe.Time vs.",i,"=== Skipping. Only one class or unique value in variable",sep=" "));
			retobj[["Label"]] <- paste("Exe.Time vs.",i,sep=" ");
			retobj[["json"]] <- paste('{"Label":"Exe.Time vs. ',i,'","Reference":"","Intercept":"","Slope":"","Message":"Only one Class or Value"}',sep="");
		} else {

			# Fair Sample
			faux1 <- table(ds[,i]);
			if (all(faux1[faux1 < minsamples])) { threshold <- minsamples; } else { threshold <- min(faux1[faux1 >= minsamples]); }

			dsaux <- data.frame(vin=NA, vout=NA);
			names(dsaux)[1] = i;
			names(dsaux)[2] = vout;
			for (j in names(faux1))
			{
				selected <- sample(1:faux1[j],min(faux1[j],threshold));
				dsaux_b <- ds[ds[,i]==j,c(vout,i)];
				dsaux <- rbind(dsaux,dsaux_b[selected,]);
			}

			# Find Slopes
			dsout <- dsaux[,vout];
			dsin <- dsaux[,i];
			b <- ols(dsout ~ dsin);
			nols <- names(b$coefficients);

			if (class(dsin) %in% c("factor","character")) retobj[["Reference"]] <- levels(as.factor(dsin))[1];
			retobj[["Label"]] <- paste("Exe.Time vs.",i,sep=" ");
			retobj[["Intercept"]] <- b$coefficients[[1]];
			for (j in 2:length(b$coefficients)) retobj[["Slope"]][[nols[j]]] <- b$coefficients[[j]];

			# Print on screen
			if (quiet == 0)
			{
				if (class(dsin) %in% c("factor","character")) { ref1 <- paste("Reference:",retobj[["Reference"]],sep=" "); } else { ref1 <- NULL; }
				saux1 <- paste("Exe.Time vs.",i,"===",ref1,"Intercept:",retobj[["Intercept"]],sep=" ");
				for (j in 1:length(retobj[["Slope"]])) saux1 <- paste(saux1,"Slope (",names(retobj[["Slope"]])[j],"):",retobj[["Slope"]][j],sep=" ");
				print(saux1);
			}

			jaux <- NULL;
			for (j in 1:length(retobj[["Slope"]])) jaux <- paste(jaux,',"',names(retobj[["Slope"]])[j],'":"',retobj[["Slope"]][j],'"',sep="");
			retobj[["json"]] <- paste('{"Label":"Exe.Time vs. ',i,'","Reference":"',retobj[["Reference"]],'","Intercept":"',retobj[["Intercept"]],'","Slope":{',substring(jaux,2),'},"Message":""}',sep="");
		}
		retval[[i]] <- retobj;
	}

	if (!is.null(saveall))
	{
		jaux <- NULL;
		for (i in vin) jaux <- paste(jaux,",",retval[[i]][["json"]],sep="");
		fileConn <- file(paste(saveall,"-json.dat",sep=""));
		writeLines(paste("[",substring(jaux,2),"]",sep=""), fileConn);
		close(fileConn);

		aloja_save_object(retval,tagname=saveall);
	}

	retval;
}

aloja_variable_quicklm <- function (ds, vin, vout, saveall = NULL, sample = 1)
{
	if (!is.numeric(sample)) sample <- as.numeric(sample); if (sample < 0 || sample > 1) { sample <- 1; print("WARNING: Invalid sample ratio"); }

	retval <- list();

	dsbin <- aloja_binarize_ds(ds[,c("ID",vin,vout)]);

	if (sample < 1)
	{
		ssize <- ceil(nrow(ds) * sample);
		km1 <- kmeans(dsbin[,(!colnames(dsbin) %in% c("ID"))],centers=ssize);
		dsbin <- as.data.frame(km1$centers);
	}

	retval[["ds_original"]] <- ds;
	retval[["dataset"]] <- dsbin;
	retval[["model"]] <- lm(dsbin[,vout] ~ ., data=dsbin[,(!colnames(dsbin) %in% c("ID",vout))]);

	retval[["mae"]] <- mean(abs(retval$model$fitted.values - dsbin[,vout]));
	retval[["rae"]] <- mean(abs((retval$model$fitted.values - dsbin[,vout])/dsbin[,vout]));
	retval[["coefs"]] <- t(retval$model$coefficients);
	retval[["sample"]] <- sample;

	jaux <- NULL;
	for (j in 1:length(retval$coefs)) jaux <- paste(jaux,',"',colnames(retval$coefs)[j],'":"',retval$coefs[j],'"',sep="");
	retval[["json"]] <- paste('{"Regression":{',substring(jaux,2),'},"MAE":',retval$mae,',"RAE":',retval$rae,',"Sample":',retval$sample,'}',sep="");

	if (!is.null(saveall))
	{
		fileConn <- file(paste(saveall,"-json.dat",sep=""));
		writeLines(retval$json, fileConn);
		close(fileConn);

		aloja_save_object(retval,tagname=saveall);
	}

	retval;
}

aloja_variable_quickrt <- function (ds, vin, vout, saveall = NULL, mparam = 5, simple = 1, sample = 1)
{
	if (!is.integer(mparam)) mparam <- as.integer(mparam);
	if (!is.integer(simple)) simple <- as.integer(simple); if (simple < 0 || simple > 1) { simple <- 1; print("WARNING: Invalid simple parameter"); }
	if (!is.numeric(sample)) sample <- as.numeric(sample); if (sample < 0 || sample > 1) { sample <- 1; print("WARNING: Invalid sample ratio"); }

	retval <- list();

	dsbin <- aloja_binarize_ds(ds[,c("ID",vin,vout)]);

	if (sample < 1)
	{
		ssize <- ceil(nrow(ds) * sample);
		km1 <- kmeans(dsbin[,(!colnames(dsbin) %in% c("ID"))],centers=ssize);
		dsbin <- as.data.frame(km1$centers);
	}

	retval[["ds_original"]] <- ds;
	retval[["dataset"]] <- dsbin;
	retval[["model"]] <- qrt.tree(formula=vout ~ .,dataset=dsbin[,(!colnames(dsbin) %in% c("ID"))],m=mparam,simple=simple);

	retval[["mae"]] <- retval$model$mae;
	retval[["rae"]] <- retval$model$rae;

	retval[["sample"]] <- sample;
	retval[["json"]] <- qrt.json(retval$model);

	if (!is.null(saveall))
	{
		fileConn <- file(paste(saveall,"-json.dat",sep=""));
		writeLines(retval$json, fileConn);
		close(fileConn);

		png(paste(saveall,"-tree.png",sep=""),width=1000,height=500);
		qrt.plot.tree(retval$model);
		dev.off();

		aloja_save_object(retval,tagname=saveall);
	}

	retval;
}

