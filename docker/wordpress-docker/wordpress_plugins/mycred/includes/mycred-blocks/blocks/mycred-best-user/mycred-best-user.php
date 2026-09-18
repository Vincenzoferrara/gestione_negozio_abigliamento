<?php

namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_best_user_block') ) :

    class mycred_best_user_block {

        public function __construct() {

            wp_register_script(
                'mycred-best-user', 
                plugins_url('index.js', __FILE__), 
                array( 
                    'wp-blocks', 
                    'wp-element', 
                    'wp-components', 
                    'wp-block-editor'
                )
            );

            register_block_type( 
                __DIR__, 
                array( 'render_callback' => array( $this, 'render_block' ) )
            );
        
        }



        public function render_block( $attributes, $content ) {
            
            $content = "";

            if ( isset( $attributes['content'] ) )
                $content = $attributes['content'];
            
            unset( $attributes['content'] );

            return "[mycred_best_user " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]" . $content . "[/mycred_best_user]";

        }

    }

endif;

new mycred_best_user_block();