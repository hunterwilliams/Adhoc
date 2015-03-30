xquery version "1.0-ml";

import module namespace render-view = "http://render-view"
  at "/view/render-view.xqy";
import module namespace lib-search = "http://lib-search" at "/lib/l-search.xqy";
import module namespace search = "http://marklogic.com/appservices/search"
    at "/MarkLogic/appservices/search/search.xqy";

declare function local:render-link($uri as xs:string, $db as xs:string) as element()*{
  <a href="/detail?uri={$uri}&amp;db={$db}"  >{fn:string($uri)}</a>
};
let $default-search-options := <options xmlns="http://marklogic.com/appservices/search">
  <concurrency-level>8</concurrency-level>
  <debug>0</debug>
  <page-length>10</page-length>
  <search-option>score-logtfidf</search-option>
  <quality-weight>1.0</quality-weight>
  <return-aggregates>true</return-aggregates>
  <return-constraints>false</return-constraints>
  <return-facets>true</return-facets>
  <return-frequencies>true</return-frequencies>
  <return-qtext>true</return-qtext>
  <return-query>false</return-query>
  <return-results>true</return-results>
  <return-metrics>true</return-metrics>
  <return-similar>false</return-similar>
  <return-values>true</return-values>
  <transform-results apply="snippet">
    <per-match-tokens>30</per-match-tokens>
    <max-matches>4</max-matches>
    <max-snippet-chars>200</max-snippet-chars>
    <preferred-elements/>
  </transform-results>
  <searchable-expression>fn:collection()</searchable-expression>
  <sort-order direction="descending">
    <score/>
  </sort-order>
  <term apply="term">
    <empty apply="all-results"/>
  </term>
  <constraint name="inDir">
    <custom facet="false">
      <parse apply="inDir" ns="http://lib-search" at="/lib/l-search.xqy"/>
    </custom>
  </constraint>
  <constraint name="docType">
    <custom facet="false">
      <parse apply="docType" ns="http://lib-search" at="/lib/l-search.xqy"/>
    </custom>
  </constraint>
  <grammar>
    <quotation>"</quotation>
    <implicit>
      <cts:and-query strength="20" xmlns:cts="http://marklogic.com/cts"/>
    </implicit>
    <starter strength="30" apply="grouping" delimiter=")">(</starter>
    <starter strength="40" apply="prefix" element="cts:not-query">-</starter>
    <joiner strength="10" apply="infix" element="cts:or-query" tokenize="word">OR</joiner>
    <joiner strength="20" apply="infix" element="cts:and-query" tokenize="word">AND</joiner>
    <joiner strength="30" apply="infix" element="cts:near-query" tokenize="word">NEAR</joiner>
    <joiner strength="30" apply="near2" consume="2" element="cts:near-query">NEAR/</joiner>
    <joiner strength="32" apply="boost" element="cts:boost-query" tokenize="word">BOOST</joiner>
    <joiner strength="35" apply="not-in" element="cts:not-in-query" tokenize="word">NOT_IN</joiner>
    <joiner strength="50" apply="constraint">:</joiner>
    <joiner strength="50" apply="constraint" compare="LT" tokenize="word">LT</joiner>
    <joiner strength="50" apply="constraint" compare="LE" tokenize="word">LE</joiner>
    <joiner strength="50" apply="constraint" compare="GT" tokenize="word">GT</joiner>
    <joiner strength="50" apply="constraint" compare="GE" tokenize="word">GE</joiner>
    <joiner strength="50" apply="constraint" compare="NE" tokenize="word">NE</joiner>
  </grammar>
</options>

let $database := "Documents"
let $search-text := xdmp:get-request-field("search-text")
let $search-options as element(search:options) := 
  (:if (xdmp:get-request-field("search-options")) then
    xdmp:unquote(xdmp:get-request-field("search-options"))/search:options
  else:)
    $default-search-options
let $search-start := 
  if (xdmp:get-request-field("search-start")) then
    xs:unsignedLong(xdmp:get-request-field("search-start"))
  else
    1
let $results := 
  if ($search-text) then
    lib-search:search($search-text,$search-options,$search-start,$database)
  else
    ()
let $html :=
  <div>
    <div class="search-area">
      <form name="searchForm" method="get" action="/advanced-search" id="searchForm">
        <fieldset>
        <div class="input-group">
          <input type="text" name="search-text" id="search" class="form-control" placeholder="Search for..." value="{$search-text}"/>
          <span class="input-group-btn">
            <button class="btn btn-default" type="sumbit">Search</button>
          </span>
        </div>
        </fieldset>
      </form>
    </div>
    <div class="results-area">
      {
        if (fn:count($results) = 0) then
          ()
        else if ($results/@total = 0 and fn:string($search-text) = "") then
          "Hit Search to get your results"
        else if ($results/@total = 0) then
          "No results"
        else
          <div>
            {lib-search:render-pagination($results, $search-options, $search-text)}
            <table class="table table-striped">
            <tr><th>Type</th><th>URI</th></tr>
              {
                for $result in $results/search:result
                  let $uri := fn:string($result/@uri)
                  return <tr><td>{lib-search:node-name($uri,$database)}</td><td>{local:render-link($uri,$database)}</td></tr>
              }
            </table>
          </div>
      }
    </div>
  </div>
   
return render-view:display("Advanced Search (BETA)",$html)