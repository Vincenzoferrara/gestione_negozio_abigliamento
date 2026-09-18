<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_sales_history') ) :
    class mycred_sales_history {

        public function __construct() {
            add_action('enqueue_block_editor_assets', array( $this, 'register_assets' ) );
        }

        public function register_assets() {
            wp_register_script(
                'mycred-sales-history', 
                plugins_url('index.js', __FILE__), 
                array( 
                    'wp-blocks', 
                    'wp-element', 
                    'wp-components', 
                    'wp-block-editor', 
                    'wp-rich-text' 
                )
            );

            register_block_type( 
                __DIR__, 
                array( 'render_callback' => array( $this, 'render_block' ) )
            );
        
            $mycred_types = mycred_get_types(true);
            $mycred_types = array_merge( array( '' => __('Select point type', 'mycred') ), $mycred_types );
            wp_localize_script('mycred-sales-history', 'mycred_types', $mycred_types);
        }

        public function render_block( $attributes, $content ) {

            return "[mycred_sales_history " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]";
        }

    }
endif;

new mycred_sales_history();