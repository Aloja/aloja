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

