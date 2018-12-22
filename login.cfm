
<cfif not isdefined("form.loginpost")
or not isdefined("form.username")
or not isdefined("form.password")>
NOT AUTHORIZED<cfabort></cfif>

<cfquery datasource="reputation" name="auth">
select * from users where username='#form.username#' 
and aes_encrypt('#form.password#','sqlgoddess') = password
</cfquery>

<cfif auth.recordcount>
	<cfset session.userauth = 1>
	<cfdump var="#session#">
		
<cfelse>
	<cfset session.userauth = 0>
	<cfset session.loginErrMsg = "Username/password not found">
</cfif>
<!--- 
<cflocation url="checks/default.cfm" addtoken="false">
<meta http-equiv="Refresh" content="0;url=http://www.whizardries.com/tools/Reputation/checks">

--->
<script LANGUAGE="Javascript">
window.location="checks/default.cfm";</script>

