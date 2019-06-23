select count(distinct Systematic_name) in genes;

select count(distinct compound_id) from compounds;

select count(distinct experiment) in experiments;

select experiment, count(distinct experiment_type) from experiments group by experiment;

select experiment, count(distinct concentration) from compound2experiment group by experiment;

select experiment, compound_id, count(distinct concentration) from compound2experiment group by experiment, compound_id order by 3 desc;


select ce.compound_id, count(distinct ce.compound_concentration_experiment_type)
from compound2experiment ce,
     compounds c
where
     ce.compound_id = c.compound_id and
     c.compound_name <> c.compound_id
group by ce.compound_id order by 2 asc limit 10;

select id from genes where Systematic_name = 'YAL011W';

select count(*) from hiphop_v
where geneid in ( select id from genes where Systematic_name = 'YAL011W' ); 

select * from hiphop_v
where gene_id = 'YAL011W'
limit 10;

select count(*) from hiphop
where gene_id = 'YAL011W';

select count(*) from hiphop_v
where gene_id = 'YAL011W';

select * from gene_correlation_v
where common_name1 = 'SEC61';