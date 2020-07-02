<cfquery name="getKey" datasource="reputation" returntype="array">
select provider, apikey
from apikeys
order by provider
</cfquery>

<!--- API Keys --->
<cfloop query="getKey" >
	<cfif getKey.provider = '250ok'>
		<cfset apikey_250 = getKey.apikey />
	<cfelseif getKey.provider = 'Return Path'>
		<cfset apikey_rp = getKey.apikey />
	</cfif>
</cfloop>

<!--- Root endpoints --->
<cfset endpoint_250 = 'https://api.250ok.com/api/1.0/' />
<cfset endpoint_rp = 'https://api.returnpath.com/v1/' />

<!--- 250ok endpoints --->
<cfset blacklist_endpoint_250 = #endpoint_250# & 'blacklistinformant/blacklisted' />
<cfset trap_endpoint_250 = #endpoint_250# & 'reputationinformant/detail' />

<!--- Return Path endpoints --->
<cfset repmon_ip_rp = #endpoint_rp# & 'repmon/ips' />
<cfset blacklists_ips_rp = #endpoint_rp# & 'blacklists/ips' />
<!---
<cfhttp url="#trap_endpoint_250#" method="get" result="Results_250" timeout="999">
      <cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
      <cfhttpparam type="header" name="Accept" value="application/json"  />
      <cfhttpparam type="header" name="x-api-key" value="#apikey_250#" />
      <cfhttpparam type="header" name="domain" value="bighand.com" />
      <cfhttpparam type="header" name="type" value="traps" />
      <cfhttpparam type="header" name="id" value="9088" />
</cfhttp>
<cfset result_ary = deserializeJSON(Results_250[3]);
<cfdump var="#result_ary#"/> 

<cfhttp url="https://api.250ok.com/api/1.0/reputationinformant/profiles" method="get" result="Results_250a" timeout="999">
      <cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
      <cfhttpparam type="header" name="Accept" value="application/json"  />
      <cfhttpparam type="header" name="x-api-key" value="#apikey_250#" />
</cfhttp>
<cfdump var="#Results_250a#"/>
--->

<cfset repmon_ip_rp=repmon_ip_rp & "?group_num=1&group_length=10&customer_name=Salesforce%20Marketing%20Cloud&order_by=score" />
<cfhttp url="#repmon_ip_rp#" method="get" result="Results_RP_bottom_10" username="#apikey_rp#" timeout="999">
<!--- <cfhttp url="#repmon_ip_rp#" method="get" result="Results_RP_bottom_10" timeout="999"> --->
	<cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded" />
      <cfhttpparam type="header" name="Accept" value="application/json" />
</cfhttp>
<!--- <cfdump var="#Results_RP_bottom_10#" /> --->
<cfset bottom10=deserializeJSON(Results_RP_bottom_10.filecontent) />
<!--- <cfdump var="#bottom10#" /> --->

<!---<cfdump var="#bottom10#" />--->

<table>
	<tr>
		<td>10 Worst Return Path Sender Scores</td>
		<td>Choose IP to investigate or enter your own</td>
	</tr>
	<tr>
		<td>
		<cfloop index="i" from="1" to="#arrayLen(bottom10.results)#">
		<cfoutput>
		#bottom10.results[i].ip#
		<table>
			<tr>
				<td>&nbsp;</td>
				<td>Sender Score:</td>
                                <cfif NOT IsNull(bottom10.results[i].sender_score)>
					<td>#bottom10.results[i].sender_score#</td>
				<cfelse>
					<td>No Score Returned</td>
				</cfif>
			</tr>
			<tr>
				<td>&nbsp</td>
				<td>Top Problem:</td>
                                <cfif NOT IsNull(bottom10.results[i].top_problem)>
					<td>#bottom10.results[i].top_problem#</td>
				<cfelse>
					<td>Nothing returned</td>
				</cfif>
			</tr>
			<tr>
				<td>&nbsp;</td>
				<td>Volume (30 day):</td>
                                <cfif NOT IsNull(bottom10.results[i].volume_30_day)>
					<td>#bottom10.results[i].volume_30_day#</td>
				<cfelse>
					<td>No volume returned</td>
				</cfif>
			</tr>

                        <cfif NOT IsNull(bottom10.results[i].top_problem)>
				<tr>
					<td>&nbsp;</td>
					<cfif bottom10.results[i].top_problem IS "complaint_rate">
						<td>Complaint rate (last 7 days):</td>
						<cfif NOT IsNull(bottom10.results[i].complaint_rate_7_day)>
							<td>#bottom10.results[i].complaint_rate_7_day#</td>
						<cfelse>
							<td>No data returned</td>
						</cfif>
					<cfelseif bottom10.results[i].top_problem IS "unknown_rate">
						<td>Unknown rate (last 7 days):</td>
						<cfif NOT IsNull(bottom10.results[i].unknown_rate_7_day)>
							<td>#bottom10.results[i].unknown_rate_7_day#</td>
						<cfelse>
							<td>No data returned</td>
						</cfif>
					<cfelseif bottom10.results[i].top_problem IS "rejected_rate">>
						<td>Rejected rate (last 7 days):</td>
						<cfif NOT IsNull(bottom10.results[i].rejected_rate_7_day)>
							<td>#bottom10.results[i].rejected_rate_7_day#</td>
						<cfelse>
							<td>No data returned</td>
						</cfif>
					<cfelse>
                                                <td>Filtered rate (last 7 days):</td>
                                                <cfif NOT IsNull(bottom10.results[i].filtered_rate_7_day)>
                                                        <td>#bottom10.results[i].filtered_rate_7_day#</td>
                                                <cfelse>
                                                    <td>No data returned</td>
                                                </cfif>
					</cfif>
				</tr>
			</cfif>
			<tr>
				<td>&nbsp;</td>
				<td>Spam traps:</td>
                                <cfif NOT IsNull(bottom10.results[i].spam_traps)>
					<td>#bottom10.results[i].spam_traps#</td>
				<cfelse>
					<td>No data returned</td>
				</cfif>
			</tr>
			<tr>
                                <td>&nbsp;</td>
                                <td>Blacklists:</td>
                                <cfif NOT IsNull(bottom10.results[i].blacklist)>
                                        <td>#bottom10.results[i].blacklist#</td>
                                <cfelse>
                                        <td>No data returned</td>
                                </cfif>
                        </tr>
		</table>
		</cfoutput>
		<br />
		</cfloop>
		</td>
		<td valign="top">
		<form name="investigate" action="ip_check.cfm" method="post">
			<input name="ip" type="text" list="comboid">
			<datalist id="comboid">
				<cfloop index="i" from="1" to="#arrayLen(bottom10.results)#">
					<cfoutput>
						<option value="#bottom10.results[i].ip#">
					</cfoutput>
				</cfloop>
			</datalist>
			<input type="submit" name="submit" value="Submit">
		</form>
		</td>
	</tr>
</table>
