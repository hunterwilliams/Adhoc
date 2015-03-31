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



(:  Render the search pagination controls :)
declare function searchyy:search-pagination($sr as element(), $page)
  as element(div)*
{
  let $showing-from := ( $page - 1 ) *  xs:int($sr/@page-length)  + 1
  let $showing-to   := $showing-from + fn:count($sr/search:result) - 1
  let $first-page   := 1
  let $last-page    := fn:ceiling(xs:int($sr/@total) div xs:int($sr/@page-length))
  return
    <div>
       <span class="pagingshowing">Showing from {$showing-from} to {$showing-to} of about {fn:format-number(xs:int($sr/@total), "#,###")} results</span>
       <br/>
       <span class="pagingpages">&nbsp;Pages:
       {
         let $border := 2
         let $pages :=
          fn:distinct-values((
            for $i in ($first-page to ($first-page + $border))
            return
              if ($i lt $page) then $i else ()
            ,
            for $i in ( ($page - $border) to ($page + $border) )
            return
              if ($i ge $first-page and $i le $last-page) then $i else ()
            ,
            for $i in (($last-page - $border) to $last-page)
            return
              if ($i gt $page) then $i else ()
          ))
         for $index in (1 to fn:count($pages))
         let $x := $pages[$index]
         return
          (
            if($x eq $page) then
              <span class="pagingcurrent">{$x}</span>
            else
              searchyy:paging-link($x)
            ,
            if($pages[$index +1] and $pages[$index + 1] ne ($x + 1)) then
              "&nbsp;...&nbsp;"
            else
              "&nbsp;&nbsp;"
          )
        }
        </span>
    </div>
 };

(:  Render an individual link for search pagination :)
declare function searchyy:paging-link($page as xs:int) as element(a)
{
  <a href="#" onclick="submitSearch({$page});">{$page}</a>
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
  let $pagination-size := xs:int(map:get($params, "pagination-size"))

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

  let $quote := """"

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

  let $search-response := searchyy:get-results($useDB, $final-search, $options, $page, $cfg:pagesize, $pagination-size)

  return
    <div id="searchresults" class="col-md-12" style="height:500px;overflow:scroll;overflow-x:hidden;">
      <div id="facetspanel" style="float:left;width:12%;padding-top:65px;padding-left:25px;">
        <input type="hidden" id="selectedFacet" value="{$searchFacet}"/>
        {
          for $facet in
            (
              $search-response//search:facet
              ,
              for $f in map:get($params, "facets")
              return
                ()
                (:cfg:faux-facets(
                  $doc-type,
                  $query-name,
                  $f/@name,
                  $additional-query,
                  $db
                ):)
            )
          return
            <table id="results" class="table table-striped">
              <thead>
                <th>{($facet/@name/fn:string())}</th>
              </thead>
              <tbody>
              {
                let $facet-list :=
                  if ($facet/@type eq "faux-facet") then
                    for $f in $facet/search:facet-value
                    order by $f/@count descending
                    return $f
                  else
                    for $f in $facet/search:facet-value
                    order by $f/@name/fn:string() ascending
                    return $f

                for $facet-value in $facet-list
                let $onclick := "submitFacetSearch(" || '''' || fn:string-join( ($facet/@name/fn:string(),$facet-value/@name/fn:string()), ":" ) || '''' || ")"
                return
                  if ($facet-value/@name/fn:string() eq fn:tokenize($searchFacet, ":")[2]) then
                    <tr>
                      <td>{fn:concat($facet-value/fn:string()," [",$facet-value/@count/fn:string(),"]")}&nbsp;<a href="#" onclick="clearFacet(1);">Remove</a></td>
                    </tr>
                  else
                    <tr>
                      <td>
                        <a href="#" onclick="{$onclick}" >
                          {fn:concat($facet-value/fn:string()," [",$facet-value/@count/fn:string(),"]")}
                        </a>
                      </td>
                    </tr>
              }
              </tbody>
            </table>
        }
      </div>
      {
        if ($search-response//search:result) then
          let $table :=
            <table id="results" border="1" class="table table-striped">
              <thead>
                <th>URI</th>
                {
                  for $name in $view/columns/column/fn:data(@name)
                  return <th>{ $name }</th>
                }
              </thead>
              <tbody>
              {
                for $result in $search-response/search:result
                let $uri := $result/fn:data(@uri)
                let $doc :=  ld:get-document($uri,$useDB)
                (: let $log := xdmp:log(fn:string(fn:exists($doc))) :)
                return
                  <tr>
                  {
                    <td><a href="../detail?uri={$uri}&amp;db={$db}" onclick="" target="_blank">{$uri}</a></td>
                    ,
                    for $column in $view/columns/column
                    let $expr := $column/fn:string(@expr)
                    let $expr :=
                      if( fn:contains($expr, "$") ) then
                        $expr
                      else
                        fn:concat("$doc", $expr)
                    return
                      <td>{ xdmp:value(fn:string($expr)) }</td>
                  }
                  </tr>
               }
               </tbody>
             </table>
           return
             <div id="resultspanel" style="float:left;width:80%;margin-left:5px;">
               {searchyy:search-pagination($search-response, $page)}
               <div>
                 <form target="_new" action="/outputs" method="post">
                   {if($cfg:create-user) then <input type="submit" value="Download" /> else ()}
                   <input type="hidden" name="data" value="{xdmp:quote($table)}"/>
                 </form>
               </div>
               <div style="overflow: auto;">
               {
                 $table
               }
               </div>
             </div>
          else
            (
              <span>No Results Found for Search Text : {$searchText}</span>
              ,
              if ($searchFacet) then
                <span> and with selected Facet : {$searchFacet}</span>
              else
                ()
            )
      }
      <div style="clear:both" />
      <span style="color:#666666;font-size:80%">
        <a href="#qrylink" id="qrylink" onclick="togglequery()" >Show/Hide Query</a>
      </span>
      <div id="qrydetails"  style="display: none;">
        <b>Search Query</b>
        <div>{ xdmp:quote( $search-response/search:query/node() ) }</div>
        <b>Additional Query</b>
        <div>{xdmp:quote( (<root>{$additional-query}</root>)/element() ) }</div>
      </div>
      <hr/>
    </div>
  };


  declare function searchyy:get-results($db,$search as xs:string+,$options as element(search:options)?,$page,$page-size,$pagination-size){
    xdmp:eval(
    'xquery version "1.0-ml";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";
    declare variable $searchQuoted external;
    declare variable $options as element(search:options)? external;
    declare variable $page external;
    declare variable $page-size external;
    declare variable $pagination-size external;
    let $search as xs:string+ := 
      if (fn:string-length($searchQuoted) > 0) then
        fn:tokenize($searchQuoted,"<join>")
      else
        ""
    return search:search(
      $search,
      $options,
      (($page - 1) * $page-size) + 1,
      $pagination-size
    )',
  ((xs:QName("searchQuoted"),fn:string-join($search,"<join>")),(xs:QName("options"),$options),(xs:QName("page"),$page),
    (xs:QName("page-size"),$page-size),(xs:QName("pagination-size"),$pagination-size)),
  <options xmlns="xdmp:eval">
    <database>{xdmp:database($db)}</database>
  </options>)
};