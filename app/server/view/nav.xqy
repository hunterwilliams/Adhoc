xquery version "1.0-ml";

module namespace nav = "http://navigation";

import module namespace  cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

declare variable $pattern := endpoints:resource-for-module(xdmp:get-request-path());

declare function nav:show-links()
{
  let $non-tester := (cu:is-logged-in() and fn:not(cu:is-tester()))
  let $tester := (cu:is-logged-in() and cu:is-tester())
  return
    nav:highlight-used-tab(
		 <div class="collapse navbar-collapse">
            <ul class="nav navbar-nav">
        {
		        if (cu:is-logged-in()) then
                 ()
		        else
              <li><a href="/login-form">Log In</a></li>
            ,
		        if($cfg:create-user and cu:is-admin()) then
		          <li><a href="/create-account-form">Create New User</a></li>
		        else
              ()
            ,
		        if ($tester or cu:is-admin())
		        then 
	            (
		            <li><a href="/adhocquery">Adhoc Query</a></li>
		            (:<li><a href="/advanced-search">Advanced Search</a></li>:)      
		        )
		        else (),
		        if ($non-tester and cu:is-admin())
                then 
			        <li class="dropdown">
			          <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">DBA Utils <span class="caret"></span></a>
			          <ul class="dropdown-menu" role="menu">
				        <li><a href="/file-upload-form">Upload XML</a></li>
				        <li><a href="/list-workspaces">Import Workspaces</a></li>
			          </ul>
			        </li>
                else ()
		    }</ul>
		    {if(cu:is-logged-in()) then
		        	<ul class="nav navbar navbar-right" style="margin-bottom:0px !important;">
			        	<li class="dropdown">
				          <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">{xdmp:get-current-user()} <span class="caret"></span></a>
				          <ul class="dropdown-menu" role="menu">
				            <li><a href="/update-user/{xdmp:get-current-user()}">Reset Password</a></li>
				            <li class="divider"></li>
					        <li><a href="/logout">Logout</a></li>
				          </ul>
				        </li>
			        </ul>

			    else
			      ()
			  }
		</div>
	)
};

declare private function nav:highlight-used-tab( $nodes as node()*) as node()* {
	for $n in $nodes
	return
		typeswitch($n)
		case text() return
			$n
		case element(li) return
		 	element {fn:name($n)} {
		 		$n/@*,
		 		if (fn:exists($n/a/@href) and fn:matches(fn:string($n/a/@href),$pattern) ) then attribute class {"active"} else (),
		 		nav:highlight-used-tab( $n/node() )
		 	}
		case element() return
			element {fn:name($n)} { $n/@*, nav:highlight-used-tab( $n/node() ) }
		default return
			()
};