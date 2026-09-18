<?php
if ( ! defined( 'myCRED_VERSION' ) ) exit;


if ( ! class_exists( 'myCRED_Admin_Notices' ) ) :
    Class myCRED_Admin_Notices {
       
        /**
         * Construct
         */
        public function __construct() {

            add_action( 'mycred_admin_init', array( $this, 'mycred_init_notice' ) );
            
        }

		/**
         * Action added
         */
        public function mycred_init_notice() {

            add_action( 'admin_notices', array( $this, 'mycred_update_notice_msg' ) );
            add_action( 'wp_ajax_mycred_update_notice', array( $this, 'mycred_update_notice' ) );

        }

		/**
         * Admin notice message
         */
        public function mycred_update_notice_msg() { 
			
			do_action( 'mycred_admin_notices_for_site' );

        }

		/**
         * Save in database
         */
        public function mycred_update_notice() {
              
        	do_action( 'mycred_save_notice_ajax' );

        }
    }
endif;

new myCRED_Admin_Notices();