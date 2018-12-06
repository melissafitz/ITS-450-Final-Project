<?php
// Initialize the session
session_start();
 
// Check if the user is already logged in, if yes then redirect him to welcome page
if(isset($_SESSION["loggedin"]) && $_SESSION["loggedin"] === true){
  header("location: index.php");
  exit;
}
 
// Include config file
require_once "config.php";
 
// Define variables and initialize with empty values
$username = $password = "";
$username_err = $password_err = "";
 
// Processing form data when form is submitted
if($_SERVER["REQUEST_METHOD"] == "POST"){
 
    // Check if username is empty
    if(empty(trim($_POST["username"]))){
        $username_err = "Please enter username.";
    } else{
	$username = mysqli_real_escape_string($username);
	$username = stripslashes($username);
        $username = trim($_POST["username"]);
    }
    
    // Check if password is empty
    if(empty(trim($_POST["password"]))){
        $password_err = "Please enter your password.";
    } else{
	$password = mysqli_real_escape_string($password);
	$password = stripslashes($password);
        $password = trim($_POST["password"]);
    }
    
    // Validate credentials
    if(empty($username_err) && empty($password_err)){
        // Prepare a select statement
        $sql = "SELECT id, username, password FROM users WHERE username = ?";
        
        if($stmt = mysqli_prepare($link, $sql)){
            // Bind variables to the prepared statement as parameters
            mysqli_stmt_bind_param($stmt, "s", $param_username);
            
            // Set parameters
            $param_username = $username;
            
            // Attempt to execute the prepared statement
            if(mysqli_stmt_execute($stmt)){
                // Store result
                mysqli_stmt_store_result($stmt);
                
                // Check if username exists, if yes then verify password
                if(mysqli_stmt_num_rows($stmt) == 1){                    
                    // Bind result variables
                    mysqli_stmt_bind_result($stmt, $id, $username, $hashed_password);
                    if(mysqli_stmt_fetch($stmt)){
                        if(password_verify($password, $hashed_password)){
                            // Password is correct, so start a new session
                            session_start();
                            
                            // Store data in session variables
                            $_SESSION["loggedin"] = true;
                            $_SESSION["id"] = $id;
                            $_SESSION["username"] = $username;                            
                            
                            // Redirect user to welcome page
                            header("location: index.php");
                        } else{
                            // Display an error message if password is not valid
                            $password_err = "The password you entered was not valid.";
                        }
                    }
                } else{
                    // Display an error message if username doesn't exist
                    $username_err = "No account found with that username.";
                }
            } else{
                echo "Oops! Something went wrong. Please try again later.";
            }
        }
        
        // Close statement
        mysqli_stmt_close($stmt);
    }
    
    // Close connection
    mysqli_close($link);
}
?>
 
<!DOCTYPE html>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
	<title><?php // Use a default page title if one wasn't provided...
		if (isset($page_title)) { 
				echo $page_title; 
		} else { 
				echo 'Life Escape - Administration'; 
		} 
		?></title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link href="/css/style.css" rel="stylesheet" type="text/css" />

<link href="/css/login.css" rel="stylesheet" type="text/css" />

	<link href="/css/superfish.css" rel="stylesheet" type="text/css" />
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript" charset="utf-8"></script>
	<script src="/js/hoverIntent.js" type="text/javascript" charset="utf-8"></script>
	<script src="/js/superfish.js" type="text/javascript" charset="utf-8"></script>
	<style type="text/css" media="screen">
		#content { background: #fff; width:100%; padding:20px 100px 30px 0px; }
		#header .nav li ul a { color:#ffe7be; text-decoration:none; text-transform:none; font-size: .75em; }

	</style>
	<script type="text/javascript"> 

		// Enable Superfish:
		$(function() { 
			$('ul.sf-menu').superfish({
				autoArrows: false,
				speed: 'fast'
			});
		}); 
	 
	</script>
	<!--[if lt IE 7]>
	   <script type="text/javascript" src="/js/ie_png.js"></script>
	   <script type="text/javascript">
	       ie_png.fix('.png, .logo h1, .box .left-top-corner, .box .right-top-corner, .box .left-bot-corner, .box .right-bot-corner, .box .border-left, .box .border-right, .box .border-top, .box .border-bot, .box .inner, .special dd, #contacts-form input, #contacts-form textarea');
	   </script>
	<![endif]-->

</head>




	<body id="page1">
	   <!-- header -->
	   <div id="header">
	      <div class="container">
		 <div class="wrapper">
		    <div class="logo"><h1><a href="logout_home.php">Life Escape</a><span>Leave your uneventful life behind</span><span>and immerse yourself in amazing games!</span></h1></div>
	         </div>

	      </div>
	   </div>
	   <!-- content -->
	   <div id="content">
	     <div class="container">


<?php
require ('login.html');
include ('./includes/footer.html');
?>
