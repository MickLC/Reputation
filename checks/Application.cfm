

<cfif not isdefined("session.USERAUTH") or session.USERAUTH is "0">
	<cfif isdefined("form.loginpost")>
	    <cfif isdefined ("form.register") and form.register is "register" and len(form.first_name) and len(form.last_name)
		and len(form.username) and len(form.password)>
		<cfquery datasource="reputation" name="register">
		insert into users (username, password, first_name, last_name) values
		('#form.username#',aes_encrypt('#form.password#','sqlgoddess'),
		'#form.first_name#','#form.last_name#')
		</cfquery>
		Thank you.  The site administrator will contact you when you have been approved.<BR><cfabort />
	    <cfelse>
		<cfquery datasource="reputation" name="auth">
		select * from users where username='#form.username#'
		and aes_encrypt('#form.password#','sqlgoddess') = password
		and approved='y'
		and approved is not null
		</cfquery>
		<cfif auth.recordcount GT 0>
			<cfset session.userauth = 1>
			<cfquery name="creds" datasource="reputation">
				select *
				from credentials
				where provider = "RP"
			</cfquery>
			<cfset authFields = { 
				 "username" = "#creds.username#",
				 "password" = "#creds.password#"
			}>
			<cfhttp url="https://api.returnpath.com/v2/auth/login" method="post" result="Auth_RP" timeout="999">
				<cfhttpparam type="header" name="Accept" value="application/json">
				<cfhttpparam type="body" name="Content-Type" value="application/json">
			</cfhttp>
			<cfdump var="Auth_RP" />
		<cfelse>
			<cfset session.userauth = 0>
			Not authorized.
			<cfabort>	
		</cfif>
	    </cfif>
	<cfelse>

		<form method="post" action=".">
		<input type="hidden" name="loginpost" value="true">
		Username: <input name="username" type="text" size="32" maxlength="64"><br />
		Password: <input name="password" type="password" size="32" maxlength="64"><br />
		First time registration: <input type="checkbox" name="register" value="register"><br>
		Please include your name when registering.<br>
		First name: <input name="first_name" type="text" size="32" maxlength="40"><br />
		Last name: <input name="last_name" type="text" size="32" maxlength="40"><br />
		<input type="submit" value="Enter" name="login"><br>

		</form>
		<cfabort />
	</cfif>
</cfif>

