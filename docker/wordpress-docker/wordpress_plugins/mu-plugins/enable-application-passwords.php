<?php
/**
 * Abilita Application Passwords su HTTP (ambiente di sviluppo Docker).
 */
add_filter('wp_is_application_passwords_available', '__return_true');
