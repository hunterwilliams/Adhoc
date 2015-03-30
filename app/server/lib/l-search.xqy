xquery version "1.0-ml";

module namespace lib-search = "http://lib-search" ;

import module namespace search = "http://marklogic.com/appservices/search"
    at "/MarkLogic/appservices/search/search.xqy";

declare function lib-search:search($qtext as xs:string,$search-options as element(search:options)?,$start as xs:unsignedLong?, $database as xs:string) as element(search:response)
{
	xdmp:eval(
		'import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
		declare variable $qtext as xs:string external;
		declare variable $start as xs:unsignedLong? external;
		declare variable $search-options as element(search:options)? external;
		
		search:search($qtext,$search-options,$start)', 
		((xs:QName("qtext"),$qtext),(xs:QName("search-options"),$search-options),(xs:QName("start"),$start)),
		<options xmlns="xdmp:eval">
		    <database>{xdmp:database($database)}</database>
		  </options>)
};

declare function lib-search:node-name($uri as xs:string, $database as xs:string)
{
	xdmp:eval(
		'
		declare variable $uri as xs:string external;
		
		xdmp:quote(fn:node-name(fn:doc($uri)/node()))', 
		((xs:QName("uri"),$uri)),
		<options xmlns="xdmp:eval">
		    <database>{xdmp:database($database)}</database>
		  </options>)
};


declare function inDir(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query)) 
as schema-element(cts:query)
{
let $query :=
<root>{
  let $dir := fn:string($right//cts:text/text())
  return
      cts:directory-query($dir,"infinity")
    }
</root>/*
return
(: add qtextconst attribute so that search:unparse will work - 
   required for some search library functions :)
element { fn:node-name($query) }
  { attribute qtextconst { 
      fn:concat($constraint-qtext, fn:string($right//cts:text)) },
    $query/@*,
    $query/node()} 
};

declare function docType($constraint-qtext as xs:string,$right as schema-element(cts:query)) as schema-element(cts:query)
{
    let $query :=
        <root>{
          let $type := getQName(fn:string($right//cts:text/text()))
          return
              cts:element-query($type,cts:and-query(()))
            }
        </root>/*
    return
(: add qtextconst attribute so that search:unparse will work - 
   required for some search library functions :)
    element { fn:node-name($query) }
      { attribute qtextconst { 
          fn:concat($constraint-qtext, fn:string($right//cts:text)) },
        $query/@*,
        $query/node()
        } 
} ;

declare function getQName($type as xs:string){
    ()
};

declare function lib-search:page-href($page,$results,$search-options,$search-text){
  fn:concat("/advanced-search?search-text=", 
    if ($search-text) then 
      fn:encode-for-uri($search-text) 
    else (),
    "&amp;search-start=",
    $page
    (:"&amp;search-options=", 
    if($search-options) then 
      fn:encode-for-uri(xdmp:quote($search-options)) 
    else ():)
  )
};
declare function lib-search:render-pagination($results,$search-options,$search-text)
{
    let $start := xs:unsignedLong($results/@start)
    let $length := xs:unsignedLong($results/@page-length)
    let $total := xs:unsignedLong($results/@total)
    let $last := xs:unsignedLong($start + $length -1)
    let $end := if ($total > $last) then $last else $total
    let $search-text := $results/search:qtext[1]/text()
    let $next := if ($total > $last) then $last + 1 else ()
    let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
    let $next-href := 
         if ($next) 
         then lib-search:page-href($next, $results, $search-options, $search-text)
         else ()
    let $previous-href := 
         if ($previous)
         then lib-search:page-href($previous, $results, $search-options, $search-text)
         else ()
    let $total-pages := fn:ceiling($total div $length)
    let $currpage := fn:ceiling($start div $length)
    let $pagemin := 
        fn:min(for $i in (1 to 4)
        where ($currpage - $i) > 0
        return $currpage - $i)
    let $rangestart := fn:max(($pagemin, 1))
    let $rangeend := fn:min(($total-pages,$rangestart + 4))
    
    return (
        <div id="countdiv"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
        if($rangestart eq $rangeend)
        then ()
        else
            <nav id="pagenumdiv"> 
              <ul class="pagination">
               { if ($previous) then <li><a href="{$previous-href}" aria-label="Previous" title="View previous {$length} results"><span aria-hidden="true">&laquo;</span></a></li> else <li class="disabled"><a href="#" aria-label="Previous"><span aria-hidden="true">&laquo;</span></a></li> }
               {
                 for $i in ($rangestart to $rangeend)
                 let $page-start := (($length * $i) + 1) - $length
                 let $page-href := lib-search:page-href($page-start, $results, $search-options, $search-text)
                 return 
                    if ($i eq $currpage) 
                    then <li class="active"><a href="#">{$i}<span class="sr-only">(current)</span></a></li>
                    else <li><a href="{$page-href}">{$i}</a></li>
                }
               { if ($next) then <li><a href="{$next-href}" aria-label="Next" title="View next {$length} results"><span aria-hidden="true">&raquo;</span></a></li> else <li class="disabled"><a href="#" aria-label="Next"><span aria-hidden="true">&raquo;</span></a></li>}
              </ul>
            </nav>
    )
};