xquery version "1.0-ml";

module namespace searchyy = "http://marklogic.com/ps/lib/searchyy";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace lx = "http://marklogic.com/ps/lib/xml"
  at "/server/lib/l-xml.xqy";
import module namespace ld = "http://marklogic.com/ps/lib/detail"
  at "/server/lib/l-detail.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" 
      at "/MarkLogic/admin.xqy";


declare namespace db="http://marklogic.com/xdmp/database";
declare option xdmp:mapping "false";

declare function searchyy:page-count($sr as element())
{
  fn:ceiling(xs:int($sr/@total) div xs:int($sr/@page-length))
};

declare function searchyy:result-count($sr as element()){
  fn:format-number(xs:int($sr/@total), "#,###")
};

declare function searchyy:index-exists($index as xs:string,$namespace as xs:string, $db as xs:string)
{
  let $config := admin:get-configuration()
  return try {fn:exists(admin:database-get-range-element-indexes($config, xdmp:database($db) )[./fn:tokenize(db:localname/text()," ")=$index and ./db:namespace-uri/text()=$namespace])}
        catch($exception){fn:false()}
  
};

declare function searchyy:search($params as map:map, $useDB as xs:string){
  let $searchText := ""
  let $searchFacet :=  map:get($params, "selectedfacet")
  let $additional-query := map:get($params, "additionalquery")
  let $page := xs:int(map:get($params, "pagenumber"))
  let $page := if ($page) then xs:int($page) else (1)

  let $db := map:get($params, "database")
  let $doc-type := map:get($params, "docType2")
  let $query-name := map:get($params, "queryName2")
  let $view-name := map:get($params, "viewName")

  let $final-search := ($searchText, $searchFacet)

  let $view :=
    if (fn:exists($view-name)) then
      cfg:get-view($doc-type, $view-name)
    else
      ()
  let $log :=
    if ($cfg:D) then
      (
        xdmp:log(text{ "db: ", $db }),
        xdmp:log(text{ "doc-type: ", $doc-type }),
        xdmp:log(text{ "view-name: ", $view-name }),
        xdmp:log(text{ "view: ", xdmp:describe($view, (), ()) })
      )
    else
      ()

  let $options :=
    <options xmlns="http://marklogic.com/appservices/search">
      <additional-query>
      {
        $additional-query
      }
      </additional-query>
      <return-results>true</return-results>
      <return-facets>true</return-facets>
      <return-query>true</return-query>
      <search-option>unfiltered</search-option>
      <transform-results apply="snippet" xmlns="http://marklogic.com/appservices/search">
        <per-match-tokens>30</per-match-tokens>
        <max-matches>3</max-matches>
        <max-snippet-chars>200</max-snippet-chars>
      </transform-results>
      {
        map:get($params, "facets")
      }
      {
        if ($doc-type = ()) then
          ()
        else if (searchyy:index-exists("lastModified", "http://test", $db)) then
          <constraint name="modifiedDate">
            <range type="xs:dateTime">
              <element ns="http://test" name="lastModified"/>
              <computed-bucket name="0Future" ge="PT0S" anchor="now">Future</computed-bucket>
              <computed-bucket name="10Min10" ge="-PT10M" lt="PT0S" anchor="now">Last 10 Min</computed-bucket>
              <computed-bucket name="15Min30" ge="-PT30M" lt="PT0S" anchor="now">Last Half Hour</computed-bucket>
              <computed-bucket name="17Min60" ge="-PT1H" lt="PT0S" anchor="now">Last Hour</computed-bucket>
              <computed-bucket name="21week" ge="-P6D" lt="PT0S" anchor="start-of-day">Last 7 Days</computed-bucket>
              <computed-bucket name="30today" ge="P0D" lt="P1D" anchor="start-of-day">Today</computed-bucket>
              <computed-bucket name="35yesterday" ge="-P1D" lt="-P0D" anchor="start-of-day">Yesterday</computed-bucket>
              <computed-bucket name="40thismonth" ge="P0M" lt="P1M" anchor="start-of-month">This Month</computed-bucket>
              <computed-bucket name="45month" ge="-P1M" lt="P0M" anchor="start-of-month">Last Month</computed-bucket>
              <computed-bucket name="60thisyear" ge="P0Y" lt="P1Y" anchor="start-of-year">This Year</computed-bucket>
              <computed-bucket name="65year" ge="-P1Y" lt="P0Y" anchor="start-of-year">Last Year</computed-bucket>
              <computed-bucket name="68older" lt="-P1Y" anchor="start-of-year">Before Last Year</computed-bucket>
            </range>
          </constraint>
        else
          ()
      }
    </options>

  let $search-response := searchyy:get-results($useDB, $final-search, $options, $page, $cfg:pagesize)

  return
    (: { result-count:4, current-page:4, page-count:10, results:[]}:)
    if ($search-response//search:result) then
      let $results :=
        for $result in $search-response/search:result
        let $uri := $result/fn:data(@uri)
        let $doc :=  ld:get-document($uri,$useDB)
        (: let $log := xdmp:log(fn:string(fn:exists($doc))) :)
        return
          <result>
          {
            <part><name>uri</name><value><a href='/detail/{$useDB}/{$uri}'>{$uri}</a></value></part>
            ,
            for $column in $view/columns/column
            let $expr := $column/fn:string(@expr)
            let $name := xs:string($column/@name)
            let $expr :=
              if( fn:contains($expr, "$") ) then
                $expr
              else
                fn:concat("$doc", $expr)
            let $value := xdmp:value(fn:string($expr))
            return
              <part><name>{fn:normalize-space($name)}</name><value>{fn:normalize-space($value)}</value></part>
          }
          </result>
      return
        <output>
          <result-count>{searchyy:result-count($search-response)}</result-count>
          <current-page>{$page}</current-page>
          <page-count>{searchyy:page-count($search-response)}</page-count>
          <result-headers><header>URI</header>{for $c in $view/columns/column return <header>{$c/@name/string()}</header>}</result-headers>
          <results>{$results}</results>
        </output>
    else
      <output>
        <result-count>0</result-count>
      </output>
  };

  declare function searchyy:make-element($name,$value){
    element {$name} { ($value) }
  };


  declare function searchyy:get-results($db,$search as xs:string+,$options as element(search:options)?,$page,$page-size){
    xdmp:eval(
    'xquery version "1.0-ml";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";
    declare variable $searchQuoted external;
    declare variable $options as element(search:options)? external;
    declare variable $page external;
    declare variable $page-size external;
    let $search as xs:string+ := 
      if (fn:string-length($searchQuoted) > 0) then
        fn:tokenize($searchQuoted,"<join>")
      else
        ""
    return search:search(
      $search,
      $options,
      (($page - 1) * $page-size) + 1,
      $page-size
    )',
  ((xs:QName("searchQuoted"),fn:string-join($search,"<join>")),(xs:QName("options"),$options),(xs:QName("page"),$page),
    (xs:QName("page-size"),$page-size)),
  <options xmlns="xdmp:eval">
    <database>{xdmp:database($db)}</database>
  </options>)
};