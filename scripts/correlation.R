# extract correlation data from objects & load them to database
# 
# Author: abrahya1
###############################################################################

library(RSQLite)
con <- dbConnect("SQLite", dbname = "../site/data/HipHop.db")

## load correlation data
correlation.files <- c('//nibr.novartis.net/CHBS-DFS/LABDATA/Inbox/PHCHBS-I21325/_project_data/HipHopViz/CMB_Exp_HIP_gene_z-score_correlation_upto193_0.15_2.Rdata',
		'//nibr.novartis.net/CHBS-DFS/LABDATA/Inbox/PHCHBS-I21325/_project_data/HipHopViz/CMB_Exp_HOP_gene_z-score_correlation_upto193_0.15_2.Rdata')

outfiles <- c('CMB_Exp_HIP_gene_z-score_correlation_upto193_0.15_2.txt','CMB_Exp_HOP_gene_z-score_correlation_upto193_0.15_2.txt')

system.time(
		ksink <- lapply(seq(1,length(correlation.files)),function(x) {
					attach(correlation.files[x])
					if(x==1) {
						cat(dbBuildTableDefinition(con,'correlation_temp',correlation.frame),file='correlation.sql')
					}
					write.table(correlation.frame,outfiles[x],row.names=F,col.names=F,sep='\t',quote=F)
					detach(pos=2)
					return(NULL)
				}
		)
)

## clean up hip/hop
hiphop.files <- c('E:/BigData/HipHop/full/HIP-scores-depivot.txt', 'E:/BigData/HipHop/full/HOP-scores-depivot.txt')

ksink <- lapply(hiphop.files,function(x) {
			require(stringr)
			tmp <- read.delim(x)
			# head(tmp)
			write.table(tmp, str_replace(x,'depivot','depivot-final'),row.names=F,col.names=F,sep='\t',quote=F)
		}
)

## clean up cpd correlation
require(stringr)
compound2experiment <- read.delim('../site/data/compound2experiment.txt',row.names=1,header=F)
names(compound2experiment) <- c('compound_concentration_experiment_type','compound_id','experiment_type','concentration')
compound2experiment$compound_concentration <- apply(compound2experiment[,c('compound_id','concentration')],1,paste,sep='',collapse='_')
compound2experiment$compound_experiment <- apply(compound2experiment[,c('compound_id','experiment_type')],1,paste,sep='',collapse='_')
compound2experiment$compound_experiment <- str_trim(compound2experiment$compound_experiment)

cpd.files <- c('E:/BigData/HipHop/full/HIP_cpd_z-score_correlation_0.1_1.txt','E:/BigData/HipHop/full/HOP_cpd_z-score_correlation_0.1_1.txt')

compound_correlation <- lapply(cpd.files,read.delim)
length(compound_correlation)
compound_correlation <- do.call('rbind',compound_correlation)
nrow(compound_correlation)

length(levels(compound_correlation$Cluster_Experiment1))
compound_correlation$Cluster_Experiment1 <- factor(compound_correlation$Cluster_Experiment1,
		levels=unique(str_trim(compound_correlation$Cluster_Experiment1))
)
length(levels(compound_correlation$Cluster_Experiment1))

length(levels(compound_correlation$Cluster_Experiment2))
compound_correlation$Cluster_Experiment2 <- factor(compound_correlation$Cluster_Experiment2,
		levels=unique(str_trim(compound_correlation$Cluster_Experiment2))
)
length(levels(compound_correlation$Cluster_Experiment2))

cluster_experiment <- with(compound_correlation,unique(c(levels(Cluster_Experiment1),levels(Cluster_Experiment2))))
length(cluster_experiment) # 5820 unique ids
head(cluster_experiment)

cluster2compound <- lapply(cluster_experiment,function(x) {
			strsplit(str_trim(x),'_')[[1]]
		}
)
cluster2compound <- do.call('rbind',cluster2compound)
cluster2compound <- data.frame(cluster2compound)
names(cluster2compound) <- c('compound_id','concentration','type','experiment')

head(cluster2compound)
cluster2compound$cluster_experiment <- cluster_experiment
cluster2compound$experiment_type <- apply(cluster2compound[,c('experiment','type')],1,paste,sep='',collapse='_')
cluster2compound$compound_concentration <- apply(cluster2compound[,c('compound_id','concentration')],1,paste,sep='',collapse='_')
cluster2compound$compound_experiment <- apply(cluster2compound[,c('compound_id','experiment_type')],1,paste,sep='',collapse='_')
cluster2compound$compound_experiment <- str_trim(cluster2compound$compound_experiment)
cluster2compound$compound_concentration_experiment_type <- apply(cluster2compound[,c('compound_id','concentration','experiment','type')],1,paste,sep='',collapse='_')

cluster2compound$final_compound_concentration_experiment_type <- cluster2compound$compound_concentration_experiment_type
cluster2compound <- within(cluster2compound, 
		final_compound_concentration_experiment_type[!compound_concentration_experiment_type %in% compound2experiment$compound_concentration_experiment_type] <- NA
)
sum(is.na(cluster2compound$final_compound_concentration_experiment_type)) # 553
sum(!is.na(cluster2compound$final_compound_concentration_experiment_type)) # 5267+553 = 5820 ok

mismatch <- subset(cluster2compound,is.na(final_compound_concentration_experiment_type) & compound_experiment %in% compound2experiment$compound_experiment)
head(mismatch)
nrow(mismatch) # 553 ok

# how many mismatch have a single compound_experiment match
n_compound_exp <- sapply(mismatch$compound_experiment,function(x) sum(compound2experiment$compound_experiment==x))
table(n_compound_exp) # 525 are single match

length(with(mismatch,final_compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)]))
length(with(compound2experiment,compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)]))
length(with(cluster2compound,final_compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)]))

head(with(compound2experiment,compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)]))
head(with(cluster2compound,compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)]))

cluster2compound <- within(cluster2compound,
		final_compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)] <- 
				with(compound2experiment,as.character(compound_concentration_experiment_type)[match(names(n_compound_exp)[n_compound_exp==1],compound_experiment)])
)
sum(is.na(cluster2compound$final_compound_concentration_experiment_type)) # 28 left...

subset(cluster2compound, !compound_concentration_experiment_type %in% compound2experiment$compound_concentration_experiment_type, select=c('final_compound_concentration_experiment_type') )

# can we resolve the others using concentration??
length(with(mismatch,final_compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==2],compound_experiment)]))
length(with(compound2experiment,compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==2],compound_experiment)]))

subset(compound2experiment,compound_experiment=='1330_0054_HIP')
subset(mismatch,compound_experiment=='1330_0054_HIP')

conc.mismatch <- merge(
		subset(mismatch,compound_experiment %in% names(n_compound_exp)[n_compound_exp==2],select=c('compound_experiment','compound_concentration_experiment_type','concentration')),
		subset(compound2experiment,compound_experiment %in% names(n_compound_exp)[n_compound_exp==2],select=c('compound_experiment','compound_concentration_experiment_type','concentration')),
		by='compound_experiment',
		suffixes=c('.cc','.c2e')
)
head(conc.mismatch)
conc.mismatch[,c('concentration.cc','concentration.c2e')]
sum(with(conc.mismatch,round(as.numeric(as.character(concentration.cc)),1)==round(as.numeric(as.character(concentration.c2e)),1))) # 23 ok!

conc.mismatch <- subset(conc.mismatch,round(as.numeric(as.character(concentration.cc)),1)==round(as.numeric(as.character(concentration.c2e)),1))

nrow(conc.mismatch)
length(with(cluster2compound,final_compound_concentration_experiment_type[match(conc.mismatch$compound_concentration_experiment_type.cc,compound_concentration_experiment_type)]))
tmp <- cbind(
		with(cluster2compound,compound_concentration_experiment_type[match(conc.mismatch$compound_concentration_experiment_type.cc,compound_concentration_experiment_type)]),
		conc.mismatch[,c('compound_concentration_experiment_type.cc','compound_concentration_experiment_type.c2e')]
)
all(tmp[,1]==tmp[,2])

cluster2compound <- within(cluster2compound,
		final_compound_concentration_experiment_type[match(conc.mismatch$compound_concentration_experiment_type.cc,compound_concentration_experiment_type)] <- 
				as.character(conc.mismatch$compound_concentration_experiment_type.c2e)
)
sum(is.na(cluster2compound$final_compound_concentration_experiment_type)) # 5 left...

# 5 left...
length(with(mismatch,final_compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==4],compound_experiment)]))
length(with(compound2experiment,compound_concentration_experiment_type[match(names(n_compound_exp)[n_compound_exp==4],compound_experiment)]))

subset(mismatch,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4])
subset(compound2experiment,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4])
is.numeric(subset(compound2experiment,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select='concentration',drop=T))
as.numeric(as.character(subset(mismatch,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select='concentration',drop=T)))
all(as.numeric(as.character(subset(mismatch,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select='concentration',drop=T))) %in%
				subset(compound2experiment,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select='concentration',drop=T)
)

small.conc.mismatch <- merge(
		subset(mismatch,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select=c('compound_experiment','compound_concentration_experiment_type','concentration')),
		subset(compound2experiment,compound_experiment %in% names(n_compound_exp)[n_compound_exp==4],select=c('compound_experiment','compound_concentration_experiment_type','concentration')),
		by='compound_experiment',
		suffixes=c('.cc','.c2e')
)

small.conc.mismatch$concentration.cc <- as.numeric(as.character(small.conc.mismatch$concentration.cc))
sum(with(small.conc.mismatch,concentration.cc==concentration.c2e)) # 5 ok
small.conc.mismatch <- subset(small.conc.mismatch,concentration.cc==concentration.c2e)

cluster2compound <- within(cluster2compound,
		final_compound_concentration_experiment_type[match(small.conc.mismatch$compound_concentration_experiment_type.cc,compound_concentration_experiment_type)] <- 
				as.character(small.conc.mismatch$compound_concentration_experiment_type.c2e)
)
sum(is.na(cluster2compound$final_compound_concentration_experiment_type)) # 0!!

# replace levels in compound_correlation
head(cluster2compound)

head(cbind(levels(compound_correlation$Cluster_Experiment1),cluster2compound$cluster_experiment))
all(levels(compound_correlation$Cluster_Experiment1)==cluster2compound$cluster_experiment) # ok
all(levels(compound_correlation$Cluster_Experiment1)==with(cluster2compound,cluster_experiment[match(levels(compound_correlation$Cluster_Experiment1),cluster_experiment)])) # ok

levels(compound_correlation$Cluster_Experiment1) <- with(cluster2compound,as.character(final_compound_concentration_experiment_type[match(levels(compound_correlation$Cluster_Experiment1),cluster_experiment)]))

head(cbind(levels(compound_correlation$Cluster_Experiment2),cluster2compound$cluster_experiment))
all(levels(compound_correlation$Cluster_Experiment2)==cluster2compound$cluster_experiment) # false -> use matching...
all(levels(compound_correlation$Cluster_Experiment2)==with(cluster2compound,cluster_experiment[match(levels(compound_correlation$Cluster_Experiment2),cluster_experiment)])) # ok

levels(compound_correlation$Cluster_Experiment2) <- with(cluster2compound,final_compound_concentration_experiment_type[match(levels(compound_correlation$Cluster_Experiment2),cluster_experiment)])

all(levels(compound_correlation$Cluster_Experiment1) %in% compound2experiment$compound_concentration_experiment_type)
all(levels(compound_correlation$Cluster_Experiment2) %in% compound2experiment$compound_concentration_experiment_type)

write.table(compound_correlation,'E:/BigData/HipHop/full/HIPHOP_cpd_z-score_correlation_0.1_1.final.txt',row.names=F,col.names=F,sep='\t',quote=F)