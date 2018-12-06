<?php
	function send_mail($to, $subject, $message, $body_plain=''){
		
		require dirname(__FILE__).'/libphp-phpmailer/PHPMailerAutoload.php';

		$mail = new PHPMailer;
		
		$mail->isSMTP();

		//SMTP debug
		$mail->SMTPDebug = 0;

		//HTML debug output
		$mail->Debugoutput = 'html';

		$mail->Host = 'smtp.gmail.com';

		$mail->Port = 465;

		$mail->SMTPSecure = 'ssl'; //ssl or tls

		//SMTP authentication
		$mail->SMTPAuth = true;

		$mail->Username = 'its4502018@gmail.com';

		$mail->Password = "ITS4502018";

		//message shows from
		$mail->setFrom('order@lifeescape.com', 'Life Escape');

		//reply-to
		$mail->addReplyTo('help@lifeescape.com', 'Life Escape');

		//send to
		$mail->addAddress($to);

		//subject line
		$mail->Subject = $subject;

		//Read an HTML and put in plane text
		$mail->msgHTML($message);

		//Replace the plain text body with one created manually
		$mail->AltBody =$body_plain;

		//send
		return $mail->send();
	}
