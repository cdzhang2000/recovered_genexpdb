elect id_ref, locustag from platformannot
group by id_ref, locustag
having count(*)>1

select id_ref, locustag, platform from platformannot
where locustag in (select locustag from platformannot
group by id_ref, locustag
having count(*)>1
)
order by 2,1,3


select locustag, count(locustag) from platformannot  where platform='GPL7445'  group by locustag  having COUNT(locustag)>1 
select distinct id_ref, locustag from platformannot where  lower(locustag)='b4380' and platform='GPL7445'

select distinct id_ref, locustag from platformannot where locustag in(select locustag from platformannot  where platform='GPL7445'  group by locustag  having COUNT(locustag)>1 ) order by 2, 1


mU-12-31-39-16-B6-F6:/home/jgrissom/loadInfo$ grep b4380 *.txt
gse15533.txt:b4380      b4380   9.729   -0.405
GSE20397_new.txt:b4380          0.014
GSE20397_old.txt:b4380          0.013
GSE20397_old.txt:b4380          -0.019
GSE20397_old.txt:b4380          0.043
GSE20397_old.txt:b4380          0.020

ubuntu@domU-12-31-39-16-B6-F6:/home/jgrissom/loadInfo$ grep z5982 *.txt
gse15533.txt:z5982      z5982   9.729   -0.405
GSE20397_new.txt:z5982          0.031
GSE20397_old.txt:z5982          0.043
GSE20397_old.txt:z5982          0.020




http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GPL7445


question:

How do we handle one ID_REF can be mapped to multiple GPL?


How do we handle b,z ids



select id_ref,locustag from platformannot where platform='GPL7445'

"ID_REF"        "LOCUSTAG"
"E100000001"    "b0001"
"E100000001"    "ecs0001"
"E100000001"    "z0001"
"E100000002"    "b0002"
"E100000002"    "ecs0002"
"E100000002"    "z0002"
"E100000003"    "b0003"
"E100000003"    "ecs0003"
"E100000003"    "z0003"
