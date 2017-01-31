import sys
import json
import httplib,base64
import smtplib
from array import *

host = ".com"

port="3000"

#Email template
email_msg_tpl = """From:no-reply<no-reply@xxxxx.com>
To: %s
MIME-Version: 1.0
Content-type: text/html
Subject: %s\n

%s

<b>Note:</b> staying in sync with updates in the develop branch is mandatory for your feature branch to be merged to develop during a release. It's highly recommended that you continually sync any changes from develop into your branch to ensure you're testing your features in the context of the latest code-base.

<br><br>This is an automatically generated email<br><br>Please contact cdc-props@xxxxx.com if any questions further
"""
# No confilct email template

no_conflict_tpl="""Dear User,<br><br><h2>WARNING: This will update your feature with AEM 6 code!</h2> This will effectively make any 5.5 test environments obsolete. <br><br><b>Update only when you are ready to to test and release for AEM 6!</b><br><br>&nbsp;&nbsp;There are new updates to the code base on the <b>develop</b> branch.You can safely sync these updates from develop into <b>%s</b>.Please follow up the below mentioned steps to perform back-merge from develop
                <ul><li>Open <a href='http://xxxxx.xxxxx.com:3000/merge-report'>http://xxxxx.xxxxx.com:3000/merge-report</a> in your browser</li>
                <li>Click on the \"<b>Safe to back-merge from develop</b>\" tab to find your branch name</li>
                <li>Press the Sync button and wait for few min to refresh to complete the process and refresh</li></ul><br>
                Thank You,<br>
		Release Team</br></br>

		"""

# Conflict email template

conflict_tpl="""Dear User,<br><br>&nbsp;&nbsp;<h2>WARNING: This will update your feature with AEM 6 code!</h2> This will effectively make any 5.5 test environments obsolete. <br><br><b>Update only when you are ready to to test and release for AEM 6!</b><br><br>There are new updates to the code base on the <b>develop</b> branch. Your branch <b>%s</b> has conflict(s) and cannot be synced automatically. Manual merge from develop to your branch is required in order to resolve the conflicts. <br>

		The below list of file(s) which has confilict.<br>
		<pre>%s</pre>

		<br>
		Thank You,<br>
                Release Team</br></br>

"""



def fail(f):
    print "[ERROR] failure:"
    sys.exit(0)

def sendmail(receiversmail,content):
    global email_msg_tpl

    #Setting send email id
    sender = 'no-reply@xxxxx.com'

    #receiver email id
    receivers =receiversmail.split(",")
    emailmsg=email_msg_tpl%(";".join(receiversmail.split(",")),"Notification Email from Release team",content)
    print(emailmsg)

    try:
       smtpObj = smtplib.SMTP('mail.xxxxx.com')
       smtpObj.sendmail(sender, receivers, emailmsg)
       print "Successfully sent email"
    except SMTPException:
       print "Error: unable to send email"


def getxxxxxData():
	global no_conflict_tpl,conflict_tpl,sendmail

        conn = httplib.HTTPConnection("{0}:{1}".format(host,port))
        try:
                urlString="/api/git/mergeReport"
		#urlString="/mergeReport.json"
                conn.request("GET",urlString, headers={'content-type':'application/json'})
                response = conn.getresponse()
        except httplib.HTTPException, e:
                fail('HTTPException:', e.status, e.reason)
        except httplib.HTTPConnection, e:
                fail('HTTPConnection:', e.status, e.reason)
        except Exception, e:
                fail(e)

        status = "Status:", response.status, response.reason
        json_data = json.loads(response.read())
        for branch in json_data["branches"]:
		notifyemail="cdc-props@xxxxx.com"
		if len(branch["branch_created_annotations"]):
			notifyemail=branch["branch_created_annotations"][0]["data"].get("Notification Email")
        	if  notifyemail is None or notifyemail=='':
			#Setting default email id if the branch does not have notification email id
			notifyemail="cdc-props@xxxxx.com"
		if branch["merge_attempt"]["status"]=="no-conflict":
	            	sendmail(notifyemail,no_conflict_tpl%(branch["name"]))
		elif branch["merge_attempt"]["status"]=="conflicts":
			committer_obj={}
			committer_name=""
	                for item in branch["commit_history"]["stdout"]:
				if item.count("|") > 2:
					committer_name=item.split("|")[1].strip()
					if committer_obj.get(committer_name,"notfound")=="notfound":
						committer_obj[committer_name]=[]

				else:
					if item != "" :
						committer_obj[committer_name].append(item.split("\t")[1])
			

			conflictfile_list="<ul>"
			for conflictfile in branch["merge_attempt"]["merge"]:
				conflictfile_list= conflictfile_list+"<li>"+conflictfile
				for cmt_author, cmt_files in committer_obj.items():
					if(cmt_files.count(conflictfile.replace("CONFLICT (content): Merge conflict in","").strip())):
						conflictfile_list=conflictfile_list+" ---> commited by :"+cmt_author
				conflictfile_list=conflictfile_list+"</li>"
					
					
			conflictfile_list= conflictfile_list+"</ul>"

			sendmail(notifyemail,conflict_tpl%(branch["name"],conflictfile_list))
		else:
			print "No need to trigger email"


getxxxxxData()