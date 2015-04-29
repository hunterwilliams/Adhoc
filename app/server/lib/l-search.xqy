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
};