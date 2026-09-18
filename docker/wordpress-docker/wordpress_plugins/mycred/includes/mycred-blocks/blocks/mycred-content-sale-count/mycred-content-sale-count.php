<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('myCRED_content_sale_count') ) :
    class myCRED_content_sale_count {

        public function __construct() {
            add_action('wp_ajax_mycred_update_sales_count', array( $this, 'mycred_update_sales_count' ));

            wp_register_script(
                'mycred-content-sale-count', 
                plugins_url('index.js', __FILE__), 
                array( 
                    'wp-blocks', 
                    'wp-element', 
                    'wp-components', 
                    'wp-block-editor', 
                    'wp-rich-text',
                    'jquery'
                ),
                null,
                true // Load script in footer
            );

            register_block_type( 
                __DIR__, 
                array( 'render_callback' => array( $this, 'render_block' ) )
            );
        }

        public function mycred_update_sales_count() {
            $post_id = intval($_POST['post_id']);
            echo mycred_get_content_sales_count($post_id);
            wp_die();
        }



        public function render_block($attributes, $content) {
            $wrapper = isset($attributes['wrapper']) ? $attributes['wrapper'] : '';
            $post_id = isset($attributes['postID']) ? intval($attributes['postID']) : null;

            $sales_count = mycred_get_content_sales_count($post_id);

            $output = '';

            if (!empty($wrapper)) {
                $output .= '<' . esc_html($wrapper) . ' class="mycred-sell-this-sales-count">';
            }

            $output .= esc_html($sales_count);

            if (!empty($wrapper)) {
                $output .= '</' . esc_html($wrapper) . '>';
            }

            return $output;
        }
    }
endif;

new myCRED_content_sale_count();
