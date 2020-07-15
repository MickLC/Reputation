<cfquery name="getKey" datasource="reputation">
	select provider, apikey
	from apikeys
	order by provider
</cfquery>
	
<!--- API Keys --->
<cfloop query="getKey" >
	<cfif getKey.provider is '250ok'>
		<cfset apikey_250 = getKey.apikey />
	<cfelseif getKey.provider is 'Return Path'>
		<cfset apikey_rp = getKey.apikey />
	<cfelseif getKey.provider is 'monapi'>
		<cfset apikey_rp = getKey.apikey />
	</cfif>
</cfloop>
	
<!--- Root endpoints --->
<cfset endpoint_250 = 'https://api.250ok.com/api/1.0/' />
<cfset endpoint_rp = 'https://api.returnpath.com/' />

<!--- 250ok endpoints --->
<cfset blacklist_endpoint_250 = #endpoint_250# & 'blacklistinformant/blacklisted' />
<cfset trap_endpoint_250 = #endpoint_250# & 'reputationinformant/detail' />

<!--- Return Path endpoints --->
<cfset repmon_senders_rp = #endpoint_rp# & 'v1/repmon/senders/' />
<cfset repmon_senders_ips_rp = #endpoint_rp# & 'v1/repmon/ips/' />
<cfset blacklists_ips_rp = #endpoint_rp# & 'v2/blacklist/address/ip/' & form.ip & '?include_previous=true' />
<cfset rp_bearer_token = 'bearer '& #session.Auth_RP.token# />

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

<cfhttp url="#blacklists_ips_rp#" method="get" result="Results_RP_blacklist" timeout="999">
	<cfhttpparam type="header" name="Accept" value="application/json">
	<cfhttpparam type="header" name="Authorization" value="#rp_bearer_token#">
</cfhttp>
<cfset rp_blacklist_result = deserializeJSON(Results_RP_blacklist.filecontent) />

<cfhttp url="https://talosintelligence.com/sb_api/query_lookup?query=/api/v2/details/ip/&query_entry=#form.ip#" timeout="50" result="talos" useragent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:64.0) Geckoo/20100101 Firefox/64.0/">
	<cfhttpparam type="header" name="Referer" value="https://talosintelligence.com/reputation_center/lookup?search=#form.ip#">
	<cfhttpparam type="header" name="Accept" value="application/json">
</cfhttp>
<cfset talos_ip_results=deserializeJSON(talos.filecontent) />
<!---<cfdump var="#talos_ip_results#">--->
<!---<cfdump var="#rp_ip_results#" />--->
<cfdump var="#rp_blacklist_result#" />
<!---<cfdump var="#form#" />--->

<html>
<head>
	<style>
		h1 {text-align:center;}
		h2 {text-align:center;}
	</style>
</head>
<body>

<cfoutput>
<h1>Summary for #rp_results.results.request#</h1>
<h2>Sending domain: 
	<cfif structKeyExists(rp_results.results,"base_domain")>
		#rp_results.results.base_domain#
	<cfelse>
		No domain found
	</cfif>
</h2>
<h3>Talos Intelligence</h3>
<p>Email Reputation: #talos_ip_results.email_score_name#<br />
Daily Spam Level: #talos_ip_results.daily_spam_level#<br />
Monthly Spam Level: #talos_ip_results.monthly_spam_level#</p>
<cfif structKeyExists(talos_ip_results,"category")>
<p style="color:red;">Listed on the Talos Security Intelligence Blacklist<br />
Reason: #talos_ip_results.category.long_description#</p>
</cfif>
<h3>Return Path</h3>
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
<br />
Risk:
	<cfif isArray(rp_results.results.sender_score)>
		None
	<cfelseif structKeyExists(rp_results.results.sender_score,"risk")>
		#rp_results.results.sender_score.risk#
	</cfif>
Blocklist History:
	<cfif isArray(rp_blacklist_result.data)>
		None
	<cfelseif structKeyExists(rp_blacklist_result.data)>
		<cfset rp_history = arrayNew(1)>
		<cfset rp_active = arrayNew(1)>
		<cfloop index="a" from="1" to="#arrayLen(rp_blacklist_result.data)#">
			<cfif rp_blacklist_result.data[a].active_hit = "True">
				<cfset rp_active = arrayAppend(rp_blacklist_result.data[a])>
			<cfelse>
				<cfset rp_history = arrayAppend(rp_blacklist_result.data[a])>
			</cfif>
		</cfloop>
		<table border="2">
			<tr>
				<td>Active</td>
				<td>Historical</td>
			</tr>
			<tr>
				<td>
					<cfif arrayLen(rp_active)>
						<cfloop index="a" from="1" to="#arrayLen(rp_active)#">
							#rp_active.blacklist_name# (#dateFormat(rp_active[a].added_date,"MMM dd, yyyy")#) <br />
						</cfloop>
					<cfelse>
						Nothing currently active.
					</cfif>
				</td>
				<td>
					<cfif arrayLen(rp_history)>
						<cfloop index="a" from="1" to="#arrayLen(rp_history)#">
							#rp_active.blacklist_name# (#dateFormat(rp_history[a].added_date,"MMM dd, yyyy")# - #dateFormat(rp_history[a].removed_date,"MMM dd, yyyy")#)<br />
						</cfloop>
					<cfelse>
						No history found.
					</cfif>
				</td>
			</tr>
		</table>
		<cfdump var="rp_history">
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
			<cfif len(rp_ip_results.results.volume.impact)><cfchartdata item="Volume" value="#abs(rp_ip_results.results.volume.impact)#"></cfif>
			<cfif len(rp_ip_results.results.rejected_rate.impact)><cfchartdata item="Rejected Rate" value="#abs(rp_ip_results.results.rejected_rate.impact)#"></cfif>
			<cfif len(rp_ip_results.results.filtered_rate.impact)><cfchartdata item="Filtered Rate" value="#abs(rp_ip_results.results.filtered_rate.impact)#"></cfif>
			<cfif len(rp_ip_results.results.unknown_rate.impact)><cfchartdata item="Unknown Rate" value="#abs(rp_ip_results.results.unknown_rate.impact)#"></cfif>
			<cfif len(rp_ip_results.results.complaint_rate.impact)><cfchartdata item="Complaint Rate" value="#abs(rp_ip_results.results.complaint_rate.impact)#"></cfif>
			<cfif len(rp_ip_results.results.spam_traps.impact)><cfchartdata item="Spamtraps" value="#abs(rp_ip_results.results.spam_traps.impact)#"></cfif>
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
	<p>Spam traps</p>
	<cfset rp_trapcount = 0 />
	<cfchart format="png" chartheight="300" chartwidth="500" title="Spam Traps" xaxistitle="Date" yaxistitle="Complaint Rate" categorylabelpositions="up_45">
		<cfchartseries type="line">
				<cfloop index="a" from="1" to="#arrayLen(rp_ip_results.results.spam_traps.trend)#">
						<cfchartdata item=#dateFormat("#rp_ip_results.results.spam_traps.trend[a].date#","d mmm yyyy")# value="#rp_ip_results.results.spam_traps.trend[a].value#">
						<cfset rp_trapcount = #rp_trapcount# + #rp_ip_results.results.spam_traps.trend[a].value#>
				</cfloop>
		</cfchartseries>
	</cfchart>
	<p>Total count: <cfoutput>#rp_ip_results.results.spam_traps.total_count# (Current)<br />
	Pristine: #rp_ip_results.results.spam_traps.pristine_count#<br />
	Recycled: #rp_ip_results.results.spam_traps.recycled_count# 
	Cumulative (last 30 days): #rp_trapcount#</cfoutput></p>

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
							<cfif len(rp_results.results.reputation_measures[i].impact)>
								<tr>
										<td>#rp_results.results.reputation_measures[i].name#</td>
										<td>#rp_results.results.reputation_measures[i].impact#</td>
								</tr>
							</cfif>
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
