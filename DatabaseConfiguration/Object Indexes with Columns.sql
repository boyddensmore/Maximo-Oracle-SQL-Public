/*******************************************************************************
*  Display all Indexes and their Columns, as displayed in Database Configuration
*******************************************************************************/

select maxsysindexes.tbname,
    maxsysindexes.name index_name,
    maxsysindexes.uniquerule,
    maxsysindexes.required,
    maxsysindexes.textsearch,
    maxsyskeys.colname index_colname,
    maxsyskeys.colseq index_colseq,
    maxsyskeys.ordering index_col_ordering
from maxsysindexes
    left join maxsyskeys on maxsyskeys.ixname = maxsysindexes.name
where tbname in ('ASSET', 'WORKORDER')
order by maxsysindexes.tbname,
    maxsysindexesid,
    maxsysindexes.name,
    maxsysindexes.uniquerule,
    maxsysindexes.required,
    maxsysindexes.textsearch,
    maxsyskeys.colname
