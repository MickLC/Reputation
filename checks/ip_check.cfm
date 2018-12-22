<cffunction
	name="ParseHTMLTag"
	access="public"
	returntype="struct"
	output="false"
	hint="Parses the given HTML tag into a ColdFusion struct.">

	<!--- Define arguments. --->
	<cfargument
		name="HTML"
		type="string"
		required="true"
		hint="The raw HTML for the tag."
		/>

	<!--- Define the local scope. --->
	<cfset var LOCAL = StructNew() />

	<!--- Create a structure for the taget tag data. --->
	<cfset LOCAL.Tag = StructNew() />

	<!--- Store the raw HTML into the tag. --->
	<cfset LOCAL.Tag.HTML = ARGUMENTS.HTML />

	<!--- Set a default name. --->
	<cfset LOCAL.Tag.Name = "" />

	<!---
		Create an structure for the attributes. Each
		attribute will be stored by it's name.
	--->
	<cfset LOCAL.Tag.Attributes = StructNew() />


	<!---
		Create a pattern to find the tag name. While it
		might seem overkill to create a pattern just to
		find the name, I find it easier than dealing with
		token / list delimiters.
	--->
	<cfset LOCAL.NamePattern = CreateObject(
		"java",
		"java.util.regex.Pattern"
		).Compile(
			"^<(\w+)"
			)
		/>

	<!--- Get the matcher for this pattern. --->
	<cfset LOCAL.NameMatcher = LOCAL.NamePattern.Matcher(
		ARGUMENTS.HTML
		) />

	<!---
		Check to see if we found the tag. We know there
		can only be ONE tag name, so using an IF statement
		rather than a conditional loop will help save us
		processing time.
	--->
	<cfif LOCAL.NameMatcher.Find()>

		<!--- Store the tag name in all upper case. --->
		<cfset LOCAL.Tag.Name = UCase(
			LOCAL.NameMatcher.Group( 1 )
			) />

	</cfif>


	<!---
		Now that we have a tag name, let's find the
		attributes of the tag. Remember, attributes may
		or may not have quotes around their values. Also,
		some attributes (while not XHTML compliant) might
		not even have a value associated with it (ex.
		disabled, readonly).
	--->
	<cfset LOCAL.AttributePattern = CreateObject(
		"java",
		"java.util.regex.Pattern"
		).Compile(
			"\s+(\w+)(?:\s*=\s*(""[^""]*""|[^\s>]*))?"
			)
		/>

	<!--- Get the matcher for the attribute pattern. --->
	<cfset LOCAL.AttributeMatcher = LOCAL.AttributePattern.Matcher(
		ARGUMENTS.HTML
		) />


	<!---
		Keep looping over the attributes while we
		have more to match.
	--->
	<cfloop condition="LOCAL.AttributeMatcher.Find()">

		<!--- Grab the attribute name. --->
		<cfset LOCAL.Name = LOCAL.AttributeMatcher.Group( 1 ) />

		<!---
			Create an entry for the attribute in our attributes
			structure. By default, just set it the empty string.
			For attributes that do not have a name, we are just
			going to have to store this empty string.
		--->
		<cfset LOCAL.Tag.Attributes[ LOCAL.Name ] = "" />

		<!---
			Get the attribute value. Save this into a scoped
			variable because this might return a NULL value
			(if the group in our name-value pattern failed
			to match).
		--->
		<cfset LOCAL.Value = LOCAL.AttributeMatcher.Group( 2 ) />

		<!---
			Check to see if we still have the value. If the
			group failed to match then the above would have
			returned NULL and destroyed our variable.
		--->
		<cfif StructKeyExists( LOCAL, "Value" )>

			<!---
				We found the attribute. Now, just remove any
				leading or trailing quotes. This way, our values
				will be consistent if the tag used quoted or
				non-quoted attributes.
			--->
			<cfset LOCAL.Value = LOCAL.Value.ReplaceAll(
				"^""|""$",
				""
				) />

			<!---
				Store the value into the attribute entry back
				into our attributes structure (overwriting the
				default empty string).
			--->
			<cfset LOCAL.Tag.Attributes[ LOCAL.Name ] = LOCAL.Value />

		</cfif>

	</cfloop>


	<!--- Return the tag. --->
	<cfreturn LOCAL.Tag />
</cffunction>

<cfquery name="getKey" datasource="reputation" returntype="array">
select provider, apikey
from apikeys
order by provider
</cfquery>

<!--- Root endpoints --->
<cfset endpoint_250 = 'https://api.250ok.com/api/1.0/' />
<cfset endpoint_rp = 'https://api.returnpath.com/v1/' />

<!--- API Keys --->
<cfset apikey_250 = getKey[1].apikey />
<cfset apikey_rp = getKey[2].apikey />

<!--- 250ok endpoints --->
<cfset blacklist_endpoint_250 = #endpoint_250# & 'blacklistinformant/blacklisted' />
<cfset trap_endpoint_250 = #endpoint_250# & 'reputationinformant/detail' />

<!--- Return Path endpoints --->
<cfset repmon_senders_rp = #endpoint_rp# & 'repmon/senders/' />
<cfset repmon_senders_ips_rp = #endpoint_rp# & 'repmon/ips/' />
<cfset blacklists_ips_rp = #endpoint_rp# & 'blacklists/ips' />

<cfset repmon_senders_rp=repmon_senders_rp & form.ip />
<cfhttp url="#repmon_senders_rp#" method="get" result="Results_RP" username="#apikey_rp#" timeout="999">
      <cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
      <cfhttpparam type="header" name="Accept" value="application/json" />
</cfhttp>
<cfset rp_results=deserializeJSON(Results_RP.filecontent) />

<cfset repmon_senders_ips_rp = repmon_senders_ips_rp & form.ip />
<cfhttp url="#repmon_senders_ips_rp#" method="get" result="Results_ips_RP" username="#apikey_rp#" timeout="999">
      <cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
      <cfhttpparam type="header" name="Accept" value="application/json" />
</cfhttp>
<cfset rp_ip_results=deserializeJSON(Results_ips_RP.filecontent) />

<cfhttp url="https://www.talosintelligence.com/reputation_center/lookup?search=#form.ip#" timeout="30" result="talos" />
<!---<cfdump var="#rp_results#" />--->
<!---<cfdump var="#form#" />--->

<html>
<head>
	<style>
		h1 {text-align:center;}
		h2 {text-align:center;}
	</style>
</head>
<body>

<!---
<cfdump var="#ParseHTMLTag(talos.filecontent)#"><cfabort>
--->

<cfset ReputationStart = findNoCase("Email Reputation",talos.filecontent)>
<cfset Reputation1 = findNoCase("<td>",talos.filecontent,ReputationStart)>
<cfset Reputation2 = findNoCase("</td>",talos.filecontent,Reputation1)>
<cfset ReputationTD = mid(talos.filecontent,Reputation1,Reputation2-Reputation1+5)>
<cfdump var="#ReputationTD#">
<br>
<br>
<br>
<br>

<!---<cfdump var="#talos#" />--->
<cfoutput>
<h1>Summary for #rp_results.results.request#</h1>
<h2>Sending domain: 
	<cfif structKeyExists(rp_results.results,"base_domain")>
		#rp_results.results.base_domain#
	<cfelse>
		No domain found
	</cfif>
</h2>
<p>Volume: 
	<cfif structKeyExists(rp_results.results,"volume")>
		#rp_results.results.volume# (#rp_results.results.volume_tier#)
	<cfelse>
		no volume found
	</cfif>
<br />
Sender Score: 
	<cfif isArray(rp_results.results.sender_score)>
		None
	<cfelseif structKeyExists(rp_results.results.sender_score,"score")>
		#rp_results.results.sender_score.score#
	<cfelse>
		N/A (something weird happened here)
	</cfif>
</p>
</cfoutput>

<cfif NOT structKeyExists(rp_ip_results,"errors")>
<!---<table border="2">
	<tr>
		<td>Measure</td>
		<td>Impact</td>
	</tr>
	<cfloop index="i" from="1" to="#arrayLen(rp_results.results.reputation_measures)#">
		<cfoutput>
			<tr>
				<td>#rp_results.results.reputation_measures[i].name#</td>
				<td>#rp_results.results.reputation_measures[i].impact#</td>
			</tr>
		</cfoutput>
	</cfloop>
</table>--->

<cfchart format="png" chartheight="300" chartwidth="500" title="Sender Score (Last 30 Days)" xaxistitle="Date" yaxistitle="Sender Score" categorylabelpositions="up_45">
	<cfchartseries type="line">
		<cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.sender_score.trend)#">
			<cfchartdata item=#dateFormat("#rp_ip_results.results.sender_score.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.sender_score.trend[a].value#">
		</cfloop>
	</cfchartseries>
</cfchart>

<!---<cfdump var="#structCount(rp_ip_results.results)#)" />--->

<cfchart format="png" chartheight="300" chartwidth="500" title="Impacts to Score" xaxistitle="Factor" yaxistitle="Points" categorylabelpositions="up_45">
	<cfchartseries type="bar">
		<cfchartdata item="Volume" value="#abs(rp_ip_results.results.volume.impact)#">
		<cfchartdata item="Rejected Rate" value="#abs(rp_ip_results.results.rejected_rate.impact)#">
		<cfchartdata item="Filtered Rate" value="#abs(rp_ip_results.results.filtered_rate.impact)#">
                <cfchartdata item="Unknown Rate" value="#abs(rp_ip_results.results.unknown_rate.impact)#">
                <cfchartdata item="Complaint Rate" value="#abs(rp_ip_results.results.complaint_rate.impact)#">
                <cfchartdata item="Blacklists" value="#abs(rp_ip_results.results.blacklist.impact)#">
                <cfchartdata item="Spamtraps" value="#abs(rp_ip_results.results.spam_traps.impact)#">
	</cfchartseries>
</cfchart>
<br />
<cfchart format="png" chartheight="300" chartwidth="500" title="Rejected Rate" xaxistitle="Date" yaxistitle="% Rejected" categorylabelpositions="up_45">
        <cfchartseries type="line">
                <cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.rejected_rate.trend)#">
                        <cfchartdata item=#dateFormat("#rp_ip_results.results.rejected_rate.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.rejected_rate.trend[a].value#">
                </cfloop>
        </cfchartseries>
</cfchart>
<cfchart format="png" chartheight="300" chartwidth="500" title="Filtered Rate" xaxistitle="Date" yaxistitle="% Filtered" categorylabelpositions="up_45">
        <cfchartseries type="line">
                <cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.filtered_rate.trend)#">
                        <cfchartdata item=#dateFormat("#rp_ip_results.results.filtered_rate.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.filtered_rate.trend[a].value#">
                </cfloop>
        </cfchartseries>
</cfchart>
<br />
<cfchart format="png" chartheight="300" chartwidth="500" title="Unknown Rate" xaxistitle="Date" yaxistitle="% Unknown" categorylabelpositions="up_45">
        <cfchartseries type="line">
                <cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.unknown_rate.trend)#">
                        <cfchartdata item=#dateFormat("#rp_ip_results.results.unknown_rate.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.unknown_rate.trend[a].value#">
                </cfloop>
        </cfchartseries>
</cfchart>
<cfchart format="png" chartheight="300" chartwidth="500" title="Complaints" xaxistitle="Date" yaxistitle="Complaint Rate" categorylabelpositions="up_45">
        <cfchartseries type="line">
                <cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.complaint_rate.trend)#">
                        <cfchartdata item=#dateFormat("#rp_ip_results.results.complaint_rate.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.complaint_rate.trend[a].value#">
                </cfloop>
        </cfchartseries>
</cfchart>
<cfelse>
<p>
<cfloop index="i" from="1" to="#arrayLen(rp_ip_results.errors)#">
	<cfoutput>#rp_ip_results.errors[i].message#</cfoutput>
</cfloop>
</p>
<cfif NOT arrayIsEmpty(rp_results.results.reputation_measures)>
<table border="2">
        <tr>
                <td>Measure</td>
                <td>Impact</td>
        </tr>
        <cfloop index="i" from="1" to="#arrayLen(rp_results.results.reputation_measures)#">
                <cfoutput>
                        <tr>
                                <td>#rp_results.results.reputation_measures[i].name#</td>
                                <td>#rp_results.results.reputation_measures[i].impact#</td>
                        </tr>
                </cfoutput>
        </cfloop>
</table><br />
<cfchart format="png" chartheight="300" chartwidth="500" title="Sender Score (Last 30 Days)" xaxistitle="Date" yaxistitle="Sender Score" categorylabelpositions="up_45">
        <cfchartseries type="line">
                <cfloop index="a" from="1" to="#arrayLen(rp_results.results.sender_score.trend)#">
                        <cfchartdata item=#dateFormat("#rp_results.results.sender_score.trend[a].date#","d mmm yyyy")# value="#rp_results.results.sender_score.trend[a].value#">
                </cfloop>
        </cfchartseries>
</cfchart>
<cfelse>
<p>No reputation data returned from Research Senders.</p>
</cfif>
</cfif>
</body>
</html>
