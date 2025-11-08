<?php
if ( ! defined('ABSPATH') ) {
    exit; // Exit if accessed directly.
}

if( ! function_exists( 'mycred_add_elementor_widget_categories' ) ):
    function mycred_add_elementor_widget_categories($elements_manager) {

        $elements_manager->add_category(
                'mycred', [
            'title' => __('myCred', 'mycred'),
            'icon' => 'fa fa-plug',
                ]
        );
        
    }
endif;

add_action( 'elementor/elements/categories_registered', 'mycred_add_elementor_widget_categories' );

if( ! function_exists( 'mycred_get_cred_types' ) ):
    function mycred_get_cred_types() {
        $mycred_types = mycred_get_types(true);
        $mycred_types = array_merge(array('' => __('Select point type', 'mycred')), $mycred_types);
        return $mycred_types;
    }
endif;

if( ! function_exists( 'mycred_get_order' ) ):
    function mycred_get_order() {
        $orders = array(
            __('Descending', 'mycred') => 'DESC',
            __('Ascending', 'mycred') => 'ASC'
        );
        return array_flip($orders);
    }
endif;
