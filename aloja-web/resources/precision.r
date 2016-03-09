# Josep Ll. Berral-García
# ALOJA-BSC-MSR hadoop.bsc.es
# 2015-07-14
# Comparision functions library for ALOJA-ML

###############################################################################
# Precision and comparision tools                                             #
###############################################################################

aloja_precision <- function (ds, vin, vout, noout = 0, sigma = 3)
{
	if (!is.integer(sigma)) sigma <- as.integer(sigma);
	if (!is.integer(noout)) noout <- as.integer(noout);

	if (noout > 0) ds <- ds[ds[,vout] < mean(ds[,vout]) + sigma * sd(ds[,vout]) & ds[,vout] > mean(ds[,vout]) - sigma * sd(ds[,vout]),];
	ds <- ds[complete.cases(ds[,c(vin,vout)]),];

	if (nrow(ds) > 1)
	{
		ds_ord <- ds[do.call("order", ds[,vin]),];

		auxset1 <- ds_ord[1,vout];
		auxvar1 <- NULL;
		for (i in 2:nrow(ds_ord))
		{
			if (all(ds_ord[i-1,vin] == ds_ord[i,vin]))
			{
				auxset1 <- c(auxset1,ds_ord[i,vout]);
				if (i == nrow(ds_ord)) auxvar1 <- c(auxvar1,var(auxset1));
			} else {
				if (length(auxset1) > 1) auxvar1 <- c(auxvar1,var(auxset1));
				auxset1 <- ds_ord[i,vout];
			}
		}
		diversity <- (nrow(unique(ds_ord[,vin])) - 1) / (nrow(ds_ord) - 1);

		if (!is.null(auxvar1)) { unprec <- sqrt(mean(auxvar1)); } else { unprec <- NA; }

		stats_mean <- mean(ds[,vout]);
		stats_stdev <- sd(ds[,vout]);
		stats_max <- max(ds[,vout]);
		stats_min <- min(ds[,vout]);

		retval <- cbind(diversity,nrow(ds_ord),unprec,stats_mean,stats_stdev,stats_max,stats_min);
	} else {
		retval <- cbind(0,1,1,ds[1,vout],0,ds[1,vout],ds[1,vout]);
	}
	colnames(retval) <- c("Diversity","Population","Unprecision","Stats [Mean]","Stats [StDev]","Stats [Max]","Stats [Min]");

	retval;
}

aloja_precision_split <- function (ds, vin, vout, vdisc, noout = 0, sigma = 3, json = 0)
{
	if (!is.integer(json)) json <- as.integer(json);

	auxlist <- list();
	for (i in unique(ds[[vdisc]]))
	{
		auxlist[[as.character(i)]] <- aloja_precision(ds[ds[,vdisc]==i,],vin,vout,noout=noout, sigma=sigma);	
	}
	retval <- do.call(rbind.data.frame, auxlist);

	if (json > 0)
	{
		h <- apply(retval,1,function(i) paste("'",paste(i,collapse="','"),"'",sep=""));
		j <- sapply(names(h),function(i) paste("['",i,"',",h[i],"]",sep=""));
		retval <- paste("[",paste(j,collapse=","),"]",sep="");
	}

	retval;
}

aloja_reunion <- function (ds, vin, vout, ...)
{
	retval <- list();

	ds <- ds[complete.cases(ds[,vin]),];

	if (nrow(ds) > 1)
	{
		ds_ord <- ds[do.call("order", ds[vin]),];

		numsets <- 0;
		auxid1 <- ds_ord[1,vout];
		for (i in 2:nrow(ds_ord))
		{
			if (all(ds_ord[i-1,vin] == ds_ord[i,vin]))
			{
				auxid1 <- c(auxid1,ds_ord[i,"ID"]);
				if (i == nrow(ds_ord))
				{
					numsets <- numsets + 1;
					retval[[numsets]] <- auxid1;
				}
			} else {
				if (length(auxid1) > 1)
				{
					numsets <- numsets + 1;
					retval[[numsets]] <- auxid1;
				}
				auxid1 <- ds_ord[i,vout];
			}
		}
	}
	retval;
}

aloja_diversity <- function (ds, vin, vout, vdisc, json = 0, noout = 0, sigma = 3)
{
	if (!is.integer(sigma)) sigma <- as.integer(sigma);
	if (!is.integer(noout)) noout <- as.integer(noout);

	if (noout > 0) ds <- ds[ds[,vout] < mean(ds[,vout]) + sigma * sd(ds[,vout]) & ds[,vout] > mean(ds[,vout]) - sigma * sd(ds[,vout]),];

	retval <- list();

	icount <- 0;
	a <- aloja_reunion(ds,vin,vout);
	for (i in 1:length(a))
	{
		if (length(unique(ds[ds$ID %in% a[[i]],vdisc])) > 1)
		{
			aux_common <- unique(ds[ds$ID %in% a[[i]],vin]);
			aux_new <- t(sapply(unique(ds[ds$ID %in% a[[i]],vdisc]), function(x) c(as.character(x),mean(ds[ds$ID %in% a[[i]] & ds[[vdisc]] == x,vout]),nrow(ds[ds$ID %in% a[[i]] & ds[[vdisc]] == x,]))));

			res <- cbind(aux_common, aux_new);
			colnames(res) <- c(vin,vdisc,vout,"Support");

			icount <- icount + 1;
			retval[[icount]] <- res;
		}
	}

	retval <- retval[order(sapply(1:length(retval),function(x) max(as.numeric(as.character(retval[[x]]$Support)))),decreasing=T)];

	if (json > 0)
	{
		if (length(retval) > 0)
		{
			auxvar1 <- retval;
			retval <- NULL;
			for (i in 1:length(auxvar1))
			{
				a <- apply(auxvar1[[i]],1,function(x) paste("'",paste(as.character(x),collapse="','"),"'",sep=""));
				auxinst <- paste("[",paste("[",paste(a,collapse="],["),"]",sep=""),"]",sep="");
				retval <- c(retval,auxinst);
			}
			retval <- paste("[",paste(retval,collapse=","),"]",sep="");
		} else {
			retval <- "[]";
		}
	}

	retval;
}

