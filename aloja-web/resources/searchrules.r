
# Josep Ll. Berral-García
# ALOJA-BSC-MSR hadoop.bsc.es
# 2015-09-07
# Pattern mining functions library for ALOJA-ML

suppressMessages(library(arules));
suppressMessages(library(methods));
options(max.print=10000000);

###############################################################################
# Pattern mining tools                                                        #
###############################################################################

aloja_bestrules_single_select <- function (ds, vin, bench, cluster, percent = "20%", minval = 50, saveall = NULL, quiet = 1)
{
	dsaux <- ds[ds$Exe.Time > minval & ds$Benchmark %in% c(bench) & ds$Cl.Name %in% c(cluster),];
	aloja_bestrules_single(dsaux, vin, percent, saveall, quiet);
}

aloja_bestrules_single <- function (ds, vin, percent = "20%", saveall = NULL, quiet = 1)
{
	if (!is.numeric(quiet)) quiet <- as.numeric(quiet);

	# Selected "Best" Executions
	q1 <- as.numeric(quantile(ds$Exe.Time,probs=seq(0,1,0.05))[percent]);
	dsauxq1 <- ds[ds$Exe.Time <= q1,vin];
	for (fck in names(dsauxq1)) if (!is.factor(dsauxq1[[fck]])) dsauxq1[[fck]] <- as.factor(dsauxq1[[fck]]);

	# Most Frequent Patterns for Single Attributes
	if (quiet == 1) sink("/dev/null");
	trans1 <- as(dsauxq1, "transactions");
	rules1 <- apriori(trans1, parameter= list(supp=0.1, conf=0.1));
	if (quiet == 1) sink();

	dfaux1 <- as(rules1, "data.frame");
	dfaux2 <- do.call(rbind,strsplit(as.character(dfaux1$rules)," => "));
	colnames(dfaux2) <- c("precedent","consequent");
	retval <- cbind(dfaux1,dfaux2);

	# Dump to file
	if (!is.null(saveall))
	{
		sink(paste("rules-",saveall,".data",sep=""));
		inspect(sort(rules1, by = "support"));
		sink();

		sink(paste("rules-",saveall,"-ns.data",sep=""));
		inspect(rules1);
		sink();
	}

	# Add extra information
	auxnump <- nchar(as.character(retval$precedent)) - nchar(as.character(gsub("=","",retval$precedent)));
	retval <- cbind(auxnump,retval);
	colnames(retval)[1] <- "numprecs";

	retval[order(retval$numprecs,-retval$support,-retval$confidence),c("numprecs","precedent","consequent","support","confidence","lift")];
}

aloja_bestrules_pairs_select <- function (ds, vin, bench, cluster, percent = "20%", minval = 50, saveall = NULL, singles = FALSE, simplified = FALSE, quiet = 1)
{
	dsaux <- ds[ds$Exe.Time > minval & ds$Benchmark %in% c(bench) & ds$Cl.Name %in% c(cluster),];
	aloja_bestrules_pairs(dsaux, vin, percent, saveall, singles, simplified, quiet);
}

aloja_bestrules_pairs <- function (ds, vin, percent = "20%", saveall = NULL, singles = FALSE, simplified = FALSE, quiet = 1)
{
	if (!is.numeric(quiet)) quiet <- as.numeric(quiet);

	# Selected "Best" Executions
	q1 <- as.numeric(quantile(ds$Exe.Time,probs=seq(0,1,0.05))[percent]);
	dsauxq1 <- ds[ds$Exe.Time <= q1,vin];
	for (fck in names(dsauxq1)) if (!is.factor(dsauxq1[[fck]])) dsauxq1[[fck]] <- as.factor(dsauxq1[[fck]]);

	# Generation of Paired Attributes
	translist <- list();
	for (k in 1:nrow(dsauxq1))
	{
		a <- dsauxq1[k,];
		patternlist <- list();

		# Basic Occurrences (add single attributes)
		if (singles)
		{
			for (j in 1:length(vin))
			{
				auxvj <- levels(a[,j])[a[,j]];
				patternlist <- c(patternlist,paste(vin[j],auxvj,sep=":"));
			}
		}
		
		# Pairing Occurrences
		for (i in 1:(length(vin)-1))
		{
			auxvi <- levels(a[,i])[a[,i]];
			auxvii <- suppressWarnings(!is.na(as.numeric(auxvi)));

			for (j in (i+1):length(vin))
			{
				auxvj <- levels(a[,j])[a[,j]];
				auxvji <- suppressWarnings(!is.na(as.numeric(auxvj)));
				patternlist <- c(patternlist,paste(vin[i],auxvi,vin[j],auxvj,sep=":"));

				# Adding simplified paired attributes
				if (simplified)
				{
					if (auxvii && auxvji)
					{
						inti <- as.numeric(auxvi);
						intj <- as.numeric(auxvj);
						if (inti != 1 && intj != 1)
						{
							if (inti < intj) patternlist <- c(patternlist,paste(vin[i],1,vin[j],round((intj / inti),digits=2),sep=":"));
							if (inti >= intj) patternlist <- c(patternlist,paste(vin[i],round((inti / intj),digits=2),vin[j],1,sep=":"));
						}
					}
				}
			}
		}
		translist[[k]] <- unlist(patternlist);
	}

	# Most Frequent Patterns for Paired Attributes
	if (quiet == 1) sink("/dev/null");
	trans2 <- as(translist, "transactions");
	rules2 <- apriori(trans2, parameter= list(supp=0.2, conf=0.2));
	if (quiet == 1) sink();

	dfaux1 <- as(rules2, "data.frame");
	dfaux2 <- do.call(rbind,strsplit(as.character(dfaux1$rules)," => "));
	colnames(dfaux2) <- c("precedent","consequent");
	retval <- cbind(dfaux1,dfaux2);

	# Dump to file
	if (!is.null(saveall))
	{
		sink(paste("rulespair-",saveall,".data",sep=""));
		inspect(sort(rules2, by = "support"));
		sink();

		sink(paste("rulespair-",saveall,"-ns.data",sep=""));
		inspect(rules2);
		sink();
	}

	# Add extra information
	auxnump <- nchar(as.character(retval$precedent)) - nchar(as.character(gsub(":","",retval$precedent)))/3;
	retval <- cbind(auxnump,retval);
	colnames(retval)[1] <- "numprecs";

	retval[order(retval$numprecs,-retval$support,-retval$confidence),c("numprecs","precedent","consequent","support","confidence","lift")];
}

aloja_bestrules_relations_select <- function (ds, vin, bench, cluster, percent = "20%", minval = 50, saveall = NULL, quiet = 1)
{
	dsaux <- ds[ds$Exe.Time > minval & ds$Benchmark %in% c(bench) & ds$Cl.Name %in% c(cluster),];
	aloja_bestrules_relations(dsaux, vin, percent, saveall, quiet);
}

aloja_bestrules_relations <- function (ds, vin, percent = "20%", saveall = NULL, quiet = 1)
{
	if (!is.numeric(quiet)) quiet <- as.numeric(quiet);

	# Selected "Best" Executions
	q1 <- as.numeric(quantile(ds$Exe.Time,probs=seq(0,1,0.05))[percent]);
	dsauxq1 <- ds[ds$Exe.Time <= q1,vin];
	for (fck in names(dsauxq1)) if (!is.factor(dsauxq1[[fck]])) dsauxq1[[fck]] <- as.factor(dsauxq1[[fck]]);

	# Generation of Paired Attributes
	translist <- list();
	for (k in 1:nrow(dsauxq1))
	{
		a <- dsauxq1[k,];
		patternlist <- list();
		
		# Pairing Occurrences (ignores non-numerical attributes)
		for (i in 1:(length(vin)-1))
		{
			auxvi <- levels(a[,i])[a[,i]];
			auxvii <- suppressWarnings(!is.na(as.numeric(auxvi)));

			for (j in (i+1):length(vin))
			{
				auxvj <- levels(a[,j])[a[,j]];
				auxvji <- suppressWarnings(!is.na(as.numeric(auxvj)));
				
				if (auxvii && auxvji)
				{
					inti <- as.numeric(auxvi);
					intj <- as.numeric(auxvj);
					if (inti != 1 && intj != 1)
					{
						if (inti < intj) patternlist <- c(patternlist,paste(paste(vin[i],1,sep=":"),paste(vin[j],round((intj / inti),digits=2),sep=":"),sep="~"));
						if (inti >= intj) patternlist <- c(patternlist,paste(paste(vin[i],round((inti / intj),digits=2),sep=":"),paste(vin[j],1,sep=":"),sep="~"));
					} else {
						patternlist <- c(patternlist,paste(paste(vin[i],auxvi,sep=":"),paste(vin[j],auxvj,sep=":"),sep="~"));
					}
				}
			}
		}

		translist[[k]] <- unlist(patternlist);
	}

	# Most Frequent Patterns for Paired Attributes
	if (quiet == 1) sink("/dev/null");
	trans2 <- as(translist, "transactions");
	rules2 <- apriori(trans2, parameter= list(supp=0.2, conf=0.2));
	if (quiet == 1) sink();

	dfaux1 <- as(rules2, "data.frame");
	dfaux2 <- do.call(rbind,strsplit(as.character(dfaux1$rules)," => "));
	colnames(dfaux2) <- c("precedent","consequent");
	retval <- cbind(dfaux1,dfaux2);

	# Dump to file
	if (!is.null(saveall))
	{
		sink(paste("relations-",saveall,".data",sep=""));
		inspect(sort(rules2, by = "support"));
		sink();

		sink(paste("relations-",saveall,"-ns.data",sep=""));
		inspect(rules2);
		sink();
	}

	# Add extra information
	auxnump <- (nchar(as.character(retval$precedent)) - nchar(as.character(gsub("~","",retval$precedent))));
	retval <- cbind(auxnump,retval);
	colnames(retval)[1] <- "numprecs";

	retval[order(retval$numprecs,-retval$support,-retval$confidence),c("numprecs","precedent","consequent","support","confidence","lift")];
}

