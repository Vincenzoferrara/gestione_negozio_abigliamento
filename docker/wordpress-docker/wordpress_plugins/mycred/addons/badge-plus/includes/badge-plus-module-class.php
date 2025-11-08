<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if( ! class_exists( 'myCRED_Badge_Plus_Module' ) ):
    class myCRED_Badge_Plus_Module extends myCRED_Module  {

    /**
     * Require File
     * @since 1.0.0
     * @version 1.0.0
     */
    public function file( $required_file ) {
        if ( file_exists( $required_file ) )
            require_once $required_file;
    }

    /**
     * Constructor
     * @since 1.0.0
     * @version 1.0.0
     */
    public function __construct( $type = MYCRED_DEFAULT_TYPE_KEY ) {

        parent::__construct( 'myCRED_Badge_Plus_Module', array(
            'module_name' => 'badge_plus',
            'defaults'    => array(),
            'register'    => false
        ), $type );

    }

    /**
     * Module Pre Init
     * @since 1.0.0
     * @version 1.0.0
     */
    public function module_pre_init() {

        add_action( 'wp_ajax_mycred_switch_all_to_open_badge_plus', array( $this, 'mycred_switch_all_to_open_badge_plus' ) );
        
    }
     /**
     * Switch all badges to Open Badges
     * @since 1.0.0
     * @version 1.0.0
     */
     public function mycred_switch_all_to_open_badge_plus() {
        if ( ! isset( $_POST['mycred_nonce'] ) || ! wp_verify_nonce( $_POST['mycred_nonce'], 'mycred_open_badge_plus_nonce' ) ) {
            wp_die( 'Invalid nonce', '', array( 'response' => 403 ) );
        }
        
        if (!current_user_can('manage_options')) {
            wp_die();
        }
        $args = array(
            'post_type' => 'mycred_badge_plus'
        );

        $query = new WP_Query( $args );

        $badges = $query->posts;

        foreach ( $badges as $badge )
        {
            $badge_id = $badge->ID;

            mycred_update_post_meta( $badge_id, 'mycred_badge_plus_open_badge', '1' );
        }

        echo esc_html__( 'All Badges-Plus successfully switched to Open Badge.', 'mycred' );

        die();

    }

    /**
     * Hook into Init
     * @since 1.0.0
     * @version 1.0.0
     */
    public function module_init() {

        // Let others play
        do_action( 'mycred_badge_plus_init' );

        mycred_register_badge_plus();
        mycred_register_badge_types();
        $this->load_file();
        add_action( 'mycred_deleted_log_entry', array( $this, 'mycred_delete_requirement_mark' ), 10, 3 );
        add_action( 'mycred_bulk_delete_log',   array( $this, 'mycred_delete_requirement_mark_' ), 10, 3 );
        add_action( 'add_meta_boxes',           array( $this, 'add_metaboxes' ) );
        add_filter( 'mycred_add_finished',      array( $this, 'balance_adjustment' ), 20, 3 );
        add_action( 'mycred_register_assets',   array( $this, 'frontend_scripts_and_styles' ) );
        add_filter( 'mycred_module_post_types', array( $this, 'mycred_post_type_css' ) );

        //Load open badge if enabled
        $this->open_badge = false;
        $setting = mycred_get_option( 'mycred_pref_core' );

        if ( isset( $setting['open_badge'] ) && $setting['open_badge']['is_enabled'] == 1 ) {
            $this->open_badge = $setting['open_badge']['is_enabled'];
            
            $this->mycred_open_badge_plus_init();
            add_action( 'mycred_open_badges_html', array( $this, 'mycred_badge_plus_button_html' ), 20 );
            
        }
        
        $this->register_metaboxes();
        
        add_submenu_page( 
            '', 
            __( 'Earners', 'mycred' ), 
            __( 'Earners', 'mycred' ), 
            $this->core->get_point_editor_capability(), 
            'badge_earners', 
            array( $this, 'earners_page' ) 
        );

        add_shortcode( MYCRED_SLUG . '_show_all_badge_plus',  'mycred_render_all_badge_plus' );
        add_shortcode( MYCRED_SLUG . '_badge_plus',           'mycred_render_single_badge_plus' );
        add_shortcode( MYCRED_SLUG . '_user_badges',          'mycred_render_user_badge' );

    }

    public function scripts_and_styles() {

        wp_register_script(
            'mycred-badge-plus-admin', 
            plugins_url( 'assets/js/admin.js', MYCRED_BADGE_PLUS ), 
            array( 'jquery' ),
            myCRED_VERSION
        );

        wp_register_script(
            'mycred-open-badge-plus-admin', 
            plugins_url( 'assets/js/open-badge-plus.js', MYCRED_BADGE_PLUS ), 
            array( 'jquery' ),
            myCRED_VERSION
        );
        wp_localize_script(
            'mycred-open-badge-plus-admin',
            'mycred_open_badge_plus_data',
            array(
                'nonce'    => wp_create_nonce( 'mycred_open_badge_plus_nonce' ),
            )
        );
    }

    /**
     * Remove line when log entry deleted by bulk action
     * @since 1.0
     * @version 1.0
     */
    public function mycred_delete_requirement_mark_( $row_ids, $point_type, $GET ) {

        global $wpdb, $mycred_log_table;
        
        $ids = implode(",",$row_ids);
        
        $usermeta =$wpdb->prefix.'usermeta';
        
        $user_ids = $wpdb->query( 
            $wpdb->prepare(
                "DELETE FROM %i WHERE user_id IN ( SELECT DISTINCT user_id FROM %i WHERE id IN ($ids) ) AND meta_key LIKE %s",
                $usermeta,
                $mycred_log_table,
                'mycred_badge_requirement%'
            )
        );

    }

    /**
     * Remove line when log entry deleted by specific user
     * @since 1.0
     * @version 1.0
     */
    public function mycred_delete_requirement_mark( $user_id, $row_id, $point_type ) {

        global $wpdb;
        
        $usermeta = $wpdb->prefix.'usermeta';

        $wpdb->query( 
            $wpdb->prepare( 
                "DELETE FROM %i WHERE user_id = %d AND meta_key LIKE %s",
                $usermeta,
                $user_id,
                'mycred_badge_requirement%'
            ) 
        );
    }

    /**
     * Add Admin Menu Item
     * @since 2.5
     * @version 1.0
     */
    public function add_metaboxes() {

        add_mycred_meta_box(
            'mycred-badge-setting',
            __( 'Badge Settings', 'mycred' ),
            array( $this, 'metabox_badge_setting' ),
            MYCRED_BADGE_PLUS_KEY,
            'normal',
            'low'
        );

        add_mycred_meta_box(
            'mycred-badge-requirement',
            __( 'Badge Requirements', 'mycred' ),
            array( $this, 'metabox_badge_setup' ),
            MYCRED_BADGE_PLUS_KEY,
            'normal',
            'low',
            'dashicons-chart-bar'
        );

    }

    /**
     * Add Admin Menu Item
     * @since 2.5
     * @version 1.0
     */
    public function metabox_badge_setting() {

        wp_enqueue_style( 'mycred-bootstrap-grid' );
        
        $post_id = get_the_ID();

        $amount = mycred_get_post_meta( $post_id , 'mycred_points_badge_plus', true );
        $point_type = mycred_get_post_meta( $post_id , 'point_type', true );
        $congrats_msg = mycred_get_post_meta( $post_id , 'congrats_msg', true );
        $congrats_msg = ! empty( $congrats_msg ) ? $congrats_msg : '';
        $user_earned = mycred_get_post_meta( $post_id , 'mycred_user_badge_plus', true );
        $global_earned = mycred_get_post_meta( $post_id , 'mycred_global_badge_plus', true );
        ?>   
        
        <div class="mycred-badge-requirement-inside ">

            <div class="mycred-boder-line" style="border-bottom: 1px solid #e9e9e9; display: block;">
                <div class="mycred-setting-badge-plus container" style="margin: 10px; ">
                    <div class="row" style="margin-bottom: 20px;">
                        <div class="col-sm-2 col-md-2">
                            <label><?php echo esc_html__( 'Point Award: ', 'mycred' ); ?></label> 
                        </div> 
                        <div class="col-sm-10 col-md-10">
                            <div class="row">
                                <div class="col-sm-2 col-md-2">
                                    <?php 
                                    $atts = array(
                                        'class' => 'mb-4 mrr-label',
                                        'type'  => 'number',
                                        'name'  => 'mycred_points_badge_plus'
                                    );

                                    if ( ! empty( $amount ) )
                                        $atts['value'] = $amount;

                                    mycred_create_input_field( $atts );
                                    ?>
                                </div>
                                <div class="col-sm-2 col-md-8">
                                    <?php 
                                    $mycred_types = mycred_get_types();
                                    $mycred_types_atts = array(
                                        'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mrr-point-type',
                                        'name' => 'point_type'
                                    );
                                    mycred_create_select_field( $mycred_types, $point_type, $mycred_types_atts );
                                    ?>
                                </div>
                                <p class="description"><?php echo esc_html__( 'Points awarded for earning this achievement (optional). Leave empty if no points are awarded.', 'mycred' ); ?></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <?php 
            //earned by steps
        $atts = array(
            'class' => 'mb-4 mrr-label',
            'type'  => 'hidden',
            'name'  => 'complete_steps',
            'value' => 'complete_steps'
        );

        mycred_create_input_field( $atts );
            // For future go to badge-plus-function
        ?>
        
        <div class="mycred-boder-line" style="border-bottom: 1px solid #e9e9e9; display: block;">
            <div class="mycred-setting-badge-plus container" style="margin: 10px; ">
                <div class="row" style="margin-bottom: 20px;">
                    <div class="col-sm-2 col-md-2">   
                        <label><?php echo esc_html__( 'Congratulation Message: ', 'mycred' ); ?></label>
                    </div>
                    <div class="col-sm-10 col-md-10">
                        <div class="row">
                            <div class="col-sm-12 col-md-12">
                                <textarea id="mycred-badge-plus-congrats-msg" name="congrats_msg" rows="4" cols="30" class="mb-4"><?php echo esc_html( $congrats_msg );?></textarea>
                            </div>
                            <p class="description"><?php echo esc_html__( 'Displayed after achievement is earned.', 'mycred' ); ?></p>
                        </div>
                    </div>
                    
                </div>
            </div>
        </div>
        
        <div class="mycred-boder-line" style="border-bottom: 1px solid #e9e9e9; display: block;">
            <div class="mycred-setting-badge-plus container" style="margin: 10px; ">
                <div class="row" style="margin-bottom: 20px;">
                    <div class="col-sm-2 col-md-2">
                        <label><?php echo esc_html__( 'Maximum Earnings Per User: ', 'mycred' ); ?></label>
                    </div>
                    <div class="col-sm-10 col-md-10">
                        <div class="row">
                            <div class="col-sm-2 col-md-2">
                             <?php 
                             $atts = array(
                                'class' => 'mb-4 mrr-label',
                                'type'  => 'number',
                                'name'  => 'mycred_user_badge_plus'
                            );

                             if ( ! empty( $user_earned ) )
                                $atts['value'] = $user_earned;

                            mycred_create_input_field( $atts );
                            ?>
                        </div>
                        <p class="description"><?php echo esc_html__( 'Number of times a user can earn this badge (set it to 0 for no maximum).', 'mycred' ); ?></p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="mycred-boder-line">
        <div class="mycred-setting-badge-plus container" style="margin: 10px; ">
            <div class="row" style="margin-bottom: 20px;">
                <div class="col-sm-2 col-md-2">
                    <label><?php echo esc_html__( 'Global Maximum Earnings: ', 'mycred' ); ?></label>
                </div>
                <div class="col-sm-10 col-md-10">
                    <div class="row">
                        <div class="col-sm-2 col-md-2">
                         <?php 
                         $atts = array(
                            'class' => 'mb-4 mrr-label',
                            'type'  => 'number',
                            'name'  => 'mycred_global_badge_plus'
                        );

                         if ( ! empty( $global_earned ) )
                            $atts['value'] = $global_earned;

                        mycred_create_input_field( $atts );
                        ?>
                    </div>
                    <p class="description"><?php echo esc_html__( 'Number of times this badge can be earned globally (set it to 0 for no maximum).', 'mycred' ); ?></p>
                    <label><strong><?php echo esc_html__( 'Note: ', 'mycred' ); ?></strong><?php echo esc_html__( 'This limit decides how many times this achievement can be earned on your site. Setting it to 10, for example, will limit this achievement to only the first 10 users who achieve it.', 'mycred' ); ?></label>
                </div>
            </div>
        </div>
    </div>
</div>

</div>
<?php

}

    /**
     * Add Admin Menu Item
     * @since 2.5
     * @version 1.0
     */
    public function metabox_badge_setup() {

        wp_enqueue_style( 'mycred-bootstrap-grid' );
        wp_enqueue_script( 'mycred-badge-plus-admin' );
        wp_enqueue_script( MYCRED_SLUG . 'mycred-select2-script' );
        wp_enqueue_style( MYCRED_SLUG . 'mycred-select2-style' );
        wp_enqueue_style( MYCRED_SLUG . '-buttons' );

        $post_id = get_the_ID();

        $requirements = mycred_get_post_meta( $post_id, 'mycred_badge_requirements', true );

        $is_sequential = isset( $requirements['is_sequential'] ) ? $requirements['is_sequential'] : false;
        wp_nonce_field( 'mycredbadgeplus-nonce', 'mycred-badgeplus-nonce' );
        ?>
        
        <div class="mycred-badge-requirement-inside">

            <p><?php echo esc_html__( 'Define the requirements for this badge that will be considered as criteria for users.', 'mycred' ); ?></p>
            <div class="mycred-form-group">
                <label for="mrr-sequential"><strong><?php echo esc_html__( 'Sequential Requirements', 'mycred' ); ?></strong></label>
                <label class="mycred-toggle">
                    <input type="checkbox" id="mrr-sequential" <?php checked( $is_sequential, true );?>> 
                    <span class="slider round"></span>
                </label>
            </div>
            <ul class="mycred-sortable <?php echo $is_sequential ? 'sequence' : ''; ?>" id="mycred-rank-requirements-list">
                <?php 

                if ( ! empty( $requirements ) && ! empty( $requirements['requirements'] ) ) {

                    $sequence = 1;
                    foreach( $requirements['requirements'] as $requirement ) {

                        mycred_badge_requirement_html( $requirement, $sequence );
                        $sequence++;

                    }

                }

                ?>
            </ul>
            <div class="mycred-form-group">
                <button class="button mycred-button-success" id="mycred-add-badge-requirement"><?php echo esc_html__( 'Add New Badge Requirement', 'mycred' ); ?></button>
                <button class="button mycred-button-default" id="mycred-save-badge-requirement"><?php echo esc_html__( 'Save all Badge Requirement', 'mycred' ); ?></button>
                <span class="mrr-requirement-loader spinner"></span>
            </div>
        </div>

        <?php 

        $mycred_badge_requirement_template = mycred_badge_requirement_html( array(), NULL, false );

        $badge_events = mycred_get_badge_events();
        $badge_event_templates = array();

        foreach ( $badge_events as $key => $event ) {

            $requirement_class = new $event['class']();
            $badge_event_templates[ $key ] = $requirement_class->settings( array(), false );

        }

        wp_localize_script( 
            'mycred-badge-plus-admin', 
            'mycred_badge_plus_localize_data', 
            array( 
                'requirement_template' => $mycred_badge_requirement_template,
                'event_templates' => $badge_event_templates,
                'post_id' => get_the_ID()
            )
        );
    }

    public function load_file() {

        $this->file( MYCRED_BADGE_PLUS_INCLUDES_DIR     . 'badge-plus-object.php' );
        $this->file( MYCRED_BADGE_PLUS_INCLUDES_DIR     . 'badge-plus-abstract-requirement-class.php' );
        $this->file( MYCRED_BADGE_PLUS_REQUIREMENTS_DIR . 'mycred-badge-default-requirement.php' );
        $this->file( MYCRED_BADGE_PLUS_REQUIREMENTS_DIR . 'mycred-badge-balance-reached-requirement.php' );
        $this->file( MYCRED_BADGE_PLUS_REQUIREMENTS_DIR . 'mycred-badge-link-click-requirement.php' );
        $this->file( MYCRED_BADGE_PLUS_REQUIREMENTS_DIR . 'mycred-badge-registration-requirement.php' );
        $this->file( MYCRED_BADGE_PLUS_REQUIREMENTS_DIR . 'mycred-badge-earned-points-amount-requirement.php' );
        $this->file( MYCRED_BADGE_PLUS_BLOCKS_DIR       . 'badge-plus-blocks.php' );
        $this->file( MYCRED_BADGE_PLUS_INCLUDES_DIR     . '/shortcode/mycred-show-all-badges.php' );
        $this->file( MYCRED_BADGE_PLUS_INCLUDES_DIR     . '/shortcode/mycred-single-badge.php' );
        $this->file( MYCRED_BADGE_PLUS_INCLUDES_DIR     . '/shortcode/mycred-user-badges.php' );

    }

    /**
     * Add Meta Boxes
     * @since 1.1
     * @version 1.0
     */
    public function register_metaboxes() {

        if( $this->open_badge ) {

            register_post_meta(
                MYCRED_BADGE_PLUS_KEY,
                'mycred_badge_plus_open_badge',
                array( 
                    'show_in_rest' => true,
                    'single' => true,
                    'type' => 'boolean',
                    'description' => __( 'badge settings will be disable when switched to open badge.', 'mycred' ),
                    'sanitize_callback' => function( $meta_value ) {
                        return sanitize_text_field( $meta_value );
                    },
                    'auth_callback' => function() {
                        return current_user_can('edit_posts');
                    }
                )
            );

        }

    }

    /**
     * Register Frontend Scripts & Styles
     * @since 1.1
     * @version 1.3.2
     */
    public function frontend_scripts_and_styles() {

        wp_register_style(
            'mycred-badge-shortcode', 
            plugins_url( 'assets/css/mycred-badge-shortcode.css', MYCRED_BADGE_PLUS ), 
            array(),
            myCRED_BADGE_PLUS_VERSION
        );

    }

    /**
     * Style For post type
     * @since 2.6
     * @version 1.1
     */
    public function mycred_post_type_css( $classes ) {

       $classes[] ='mycred_badge_plus' ;
       return $classes;

   }

    /**
     * Init Open Badge
     * @since 2.1
     * @version 1.0
     */
    public function mycred_open_badge_plus_init() {

        $mycred_Open_Badge = new mycred_Open_Badge();

        add_action( 'mycred_after_badge_plus_assign', array( $this, 'after_badge_plus_assign' ), 10, 2 );
        add_action( 'rest_api_init',             array( $mycred_Open_Badge, 'register_open_badge_routes' ) );
        
    }

    /**
     * Init Open Badge
     * @since 2.1
     * @version 1.0
     */
    public function mycred_badge_plus_button_html() { 

        wp_enqueue_script( 'mycred-open-badge-plus-admin' ); ?>

        <div class="form-group">
            <button class="button button-large large button-primary" id="switch-all-to-open-badge-plus"><span class="dashicons dashicons-update mycred-switch-all-badges-icon"></span> <?php echo esc_html__( 'Switch All Badges (Plus) To Open Badge.', 'mycred' ); ?></button>
            </div> <?php
            
        }

    /**
     * Init Open Badge
     * @since 2.1
     * @version 1.0
     */
    public function after_badge_plus_assign( $user_id, $badge_id ) {

        $mycred_Open_Badge = new mycred_Open_Badge();

        $mycred_Open_Badge = new mycred_Open_Badge();
        $badge = mycred_badge_plus_object( $badge_id );
        
        $mycred_Open_Badge->bake_users_image( $user_id, $badge_id, $badge->main_image_url, $badge->title, $this->open_badge );
        
    }

    /**
     * Hook into Admin Init
     * @since 1.1
     * @version 1.3
     */
    public function module_admin_init() {

        add_filter( 'post_row_actions',                         array( $this, 'adjust_row_actions' ), 10, 2 );
        add_action( 'wp_ajax_mycred_save_badge_requirements',   array( $this, 'save_badge_requirements' ) );
        add_action( 'save_post_' . MYCRED_BADGE_PLUS_KEY,       array( $this, 'save_badges' ), 10, 2 );
        add_action( 'restrict_manage_posts',                    array( $this, 'filter_by_badge_type' ), 10, 1 );
        add_action( 'enqueue_block_editor_assets',              array( $this, 'register_assets' ) );
        add_filter( 'manage_' . MYCRED_BADGE_PLUS_KEY . '_posts_columns',       array( $this, 'adjust_column_headers' ), 50 );
        add_action( 'manage_' . MYCRED_BADGE_PLUS_KEY . '_posts_custom_column', array( $this, 'adjust_column_content' ), 10, 2 );
        add_action( 'mycred_user_edit_after_balances',          array( $this, 'badge_plus_user_screen' ), 10 );
        add_action( 'wp_ajax_mycred_revoke_user_badge',   array( $this, 'mycred_revoke_user_badge' ) );
        add_action( 'wp_ajax_mycred_assign_user_badge',   array( $this, 'mycred_assign_user_badge' ) );
        add_shortcode( MYCRED_SLUG . '_badge_plus',    'mycred_render_all_badge_plus' );

    }

    /**
     * Adjust Row Actions
     * @since 1.1
     * @version 1.0
     */
    public function adjust_row_actions( $actions, $post ) {

        if ( $post->post_type == MYCRED_BADGE_PLUS_KEY ) {

            unset( $actions['inline hide-if-no-js'] );

            $url = add_query_arg( 
                array( 
                    'post_type' => 'mycred_badge_plus',
                    'page' => 'badge_earners',
                    'badge_id' => $post->ID
                ), 
                admin_url('edit.php') 
            );

            $actions['badge_earners'] = '<a href="' . esc_url( $url ) . '">View Earners</a>';

        }

        return $actions;

    }

    /**
     * Save Badge requirement
     * @since 2.5
     * @version 1.0
     */
    public function save_badge_requirements() {

        if ( 
            ! current_user_can( 'edit_posts' ) ||
            ! isset( $_POST['nonce'] ) ||
            ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'mycredbadgeplus-nonce' ) ||
            ! isset( $_POST['postid'] ) ||
            ! isset( $_POST['is_sequential'] )
        ) wp_send_json('error');

            $post_id            = absint( $_POST['postid'] );
            $is_sequential      = boolval( $_POST['is_sequential'] );
            $badge_requirements = array();

            if ( ! empty( $_POST['requirements'] ) && is_array( $_POST['requirements'] ) ) 
                $badge_requirements = mycred_sanitize_array( wp_unslash( $_POST['requirements'] ) );

            $meta = mycred_update_post_meta( 
                $post_id, 
                'mycred_badge_requirements', 
                array(
                    'id' => $post_id,
                    'is_sequential' => $is_sequential,
                    'requirements'  => $badge_requirements
                ) 
            );

            wp_send_json( $meta );

        }

    /**
     * Save Badge Details
     * @since 1.1
     * @version 1.5
     */
    public function save_badges( $post_id, $post ) {

        $type = get_the_terms( $post_id, 'mycred_badge_plus_type' );

        if ( ! empty( $type[0]->term_id ) ) {

            if( ! isset( $_POST['mycred-badgeplus-nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['mycred-badgeplus-nonce'] ) ), 'mycred-badge-plus-nonce' ) ) {
                $amount = isset( $_POST['mycred_points_badge_plus'] ) ? intval( $_POST['mycred_points_badge_plus'] ) : 0;
                mycred_update_post_meta( $post_id , 'mycred_points_badge_plus', $amount );
                
                $point_type = isset( $_POST['point_type'] ) ? sanitize_text_field( wp_unslash( $_POST['point_type'] ) ) : '';
                mycred_update_post_meta( $post_id , 'point_type', $point_type );
                
                $required_steps = isset( $_POST['complete_steps'] ) ? sanitize_text_field( wp_unslash( $_POST['complete_steps'] ) ) : '';
                mycred_update_post_meta( $post_id , 'complete_steps', $required_steps );
                
                $msg = isset( $_POST['congrats_msg'] ) ? sanitize_text_field( wp_unslash( $_POST['congrats_msg'] ) ) : '';
                mycred_update_post_meta( $post_id , 'congrats_msg', $msg );
                
                $user_earned = isset( $_POST['mycred_user_badge_plus'] ) ? intval( $_POST['mycred_user_badge_plus'] ) : 0;
                mycred_update_post_meta( $post_id , 'mycred_user_badge_plus' , $user_earned );
                
                $global_earned = isset( $_POST['mycred_global_badge_plus'] ) ? intval( $_POST['mycred_global_badge_plus'] ) : 0;
                mycred_update_post_meta( $post_id , 'mycred_global_badge_plus' , $global_earned );
            }
            
        }

    }

    public function filter_by_badge_type( $post_type ){

        if( MYCRED_BADGE_PLUS_KEY !== $post_type ) return;
        
        $taxonomie = get_taxonomy( MYCRED_BADGE_PLUS_TYPE );

        $taxonomies = get_terms(  array( 'taxonomy'   => MYCRED_BADGE_PLUS_TYPE, 'hide_empty' => false ));

        $selected   = isset( $_REQUEST[ MYCRED_BADGE_PLUS_TYPE ] ) ? sanitize_key( $_REQUEST[ MYCRED_BADGE_PLUS_TYPE ] ) : ''; ?>
        
        <select  name='mycred_badge_plus_type' id='mycred_badge_plus_type' class='postform'>
            <option value='0' <?php echo ( empty( $selected ) || '0' === $selected ) ? 'selected' : ''; ?>><?php echo esc_html( $taxonomie->label ); ?></option>
            <?php 
            foreach ( $taxonomies as $key => $value ) { ?>
                <option value=<?php echo esc_attr( $value->slug ); ?> <?php echo $selected == $value->slug ? 'selected' : ''; ?>><?php echo esc_html( $value->name ); ?></option> <?php
            } 
            ?>
            </select> <?php 

        }

        public function register_assets() {

            global $post;

            if ( $post->post_type == MYCRED_BADGE_PLUS_KEY ) {

                wp_register_script(
                    'mycred-badge-plus-meta', 
                    plugins_url( 'assets/js/metaboxes.js', MYCRED_BADGE_PLUS ), 
                    array( 
                        'wp-blocks', 
                        'wp-element', 
                        'wp-components', 
                        'wp-editor',
                        'wp-plugins',
                        'wp-edit-post'
                    )
                );

                wp_localize_script( 
                    'mycred-badge-plus-meta', 
                    'mycred_badge_plus_meta_data', 
                    array(
                        'open_badge'   => (int)$this->open_badge,
                        'badgeTypesURL' => add_query_arg(
                            array(
                                'post_type' => MYCRED_BADGE_PLUS_KEY,
                                'taxonomy' => MYCRED_BADGE_PLUS_TYPE
                            ),
                            admin_url('edit-tags.php')
                        )
                    )
                );

                wp_enqueue_script( 'mycred-badge-plus-meta' );
                
            }

        }

    /**
     * Adjust Badge Plus Column Header
     * @since 1.1
     * @version 1.2
     */
    public function adjust_column_headers( $defaults ) {

        $columns                      = array();
        $columns['cb']                = $defaults['cb'];

        $columns['title']                = __( 'Badge Title', 'mycred' );
        $columns['mycred-badge-logo']    = __( 'Image', 'mycred' );
        $columns['points-award']         = __( 'Amount Awards   ', 'mycred' );
        $columns['mycred-badge-type']    = __( 'Badge Type', 'mycred' );
        $columns['date']                 = __( 'Date', 'mycred' );

        if ( $this->open_badge ) 
            $columns['mycred-open-badge-plus'] = __( 'Open Badge', 'mycred' );

        // Return
        return $columns;

    }

    /**
     * Adjust Badeg Column Content
     * @since 1.1
     * @version 1.1
     */
    public function adjust_column_content( $column_name, $post_id ) {

        $badge = mycred_badge_plus_object( $post_id );
        
        switch ( $column_name ) {

            case 'mycred-badge-logo':
            if ( ! empty( $badge->main_image ) ) {
                echo wp_kses_post( $badge->get_logo_image( 50 ) );
            }
            else {
                echo esc_html__( 'No Logo Set', 'mycred' );
            }
            break;
            case 'points-award':
            if ( ! empty( $badge->points_award ) ) {
                echo esc_html( $badge->points_award );
            }
            break;
            case 'mycred-badge-type':
            if ( ! empty( $badge->type->name ) ) {
                echo esc_html( $badge->type->name );
            }
            break;
            case 'mycred-open-badge-plus':
            echo $badge->open_badge ? 'Yes' : 'No';
            break;
            default:
            break;

        }

    }

    /**
     * User Badges Admin Screen
     * @since 1.0
     * @version 1.1
     */
    public function badge_plus_user_screen( $user ) {

        wp_enqueue_script( 'mycred-badge-plus-admin' );        
        $user_id    = $user->ID;
        $earned     = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );

        ?>
        <style type="text/css">
            .mycred-button-revoke { color: #ffffff !important; background: #eb6673 ; border-color: #dc3545 !important; outline: none !important; border-radius: 10px; cursor: pointer; }
            .mycred-button-revoke:hover{ background-color: red; }
        </style>
        <hr>
        <h3>Badges</h3>

        <div class="badge-earners">
            <h4><strong style="font-size: 15px;"><?php echo esc_html__( 'Earned Badges', 'mycred' ); ?></strong></h4>
            <div class="tablenav-pages navigation"></div>
            <table class="wp-list-table widefat mycred-earner-table">
                <thead>
                    <tr>
                        <th scope="col" id="name" class="manage-column column-name column-primary"><?php echo esc_html__( 'Name', 'mycred' ); ?></th>
                        <th scope="col" id="points" class="manage-column column-points"><?php echo esc_html__( 'Points', 'mycred' ); ?></th>
                        <th scope="col" id="date" class="manage-column column-date"><?php echo esc_html__( 'Date', 'mycred' ); ?></th>
                        <?php 
                        if( mycred_is_admin() ) { ?>
                            <th scope="col" id="action" class="manage-column column-action"><?php echo esc_html__( 'Action', 'mycred' ); ?></th><?php 
                        } ?>
                    </tr>
                </thead>
                <tbody> <?php
                if ( ! empty( $earned ) ) {
                    foreach ( $earned as $badge_id => $value ) {

                        $badge_id     =  absint( $badge_id );
                        $badge        = mycred_badge_plus_object( $badge_id );
                        $badge_image  = $badge->get_image( 'main' );    
                        $amount     = mycred_get_post_meta( $badge_id, 'mycred_points_badge_plus' ,true );

                        foreach ($value as $key => $values) { ?>
                            <tr class="mycred-badge-row-<?php echo esc_attr( $values ); ?>">
                                <td>
                                    <?php echo esc_html( $badge->title ); ?>
                                </td>
                                <td>
                                    <?php echo esc_html( $amount ); ?>
                                </td>
                                <td>
                                    <?php echo esc_html( wp_date( 'F d Y h:i A', $values ) ); ?>
                                </td>
                                <?php 
                                if( mycred_is_admin() ) { ?>
                                    <td>
                                        <button class="mycred-button-revoke revoke-reward" data-id="<?php echo esc_attr( $badge_id ); ?>" data-attr="<?php echo esc_attr( $user_id ); ?>" data-earned="<?php echo esc_attr( $values ); ?>" type="button"><?php echo esc_html__( 'Revoke Badge', 'mycred' ); ?></button>
                                        </td><?php 
                                    } ?>
                                    </tr><?php
                                } 
                            }
                        } 
                        else { ?>
                            <tr class="no-badge"> 
                                <td>
                                    <?php echo esc_html__( 'No badge Earn', 'mycred' ); ?>
                                </td>
                                </tr> <?php
                            } ?>

                        </tbody>
                        <tfoot>
                            <tr>
                                <th scope="col" id="name" class="manage-column column-name column-primary"><?php echo esc_html__( 'Name', 'mycred' ); ?></th>
                                <th scope="col" id="points" class="manage-column column-points"><?php echo esc_html__( 'Points', 'mycred' ); ?></th>
                                <th scope="col" id="date" class="manage-column column-date"><?php echo esc_html__( 'Date', 'mycred' ); ?></th>
                                <?php
                                if( mycred_is_admin() ) { ?>
                                    <th scope="col" id="action" class="manage-column column-action"><?php echo esc_html__( 'Action', 'mycred' ); ?></th><?php 
                                } ?>
                            </tr>
                        </tfoot>
                    </table>
                </div>
                <?php
                if( mycred_is_admin() ) { ?>
                    <div>
                        <h4><strong style="font-size: 15px;"><?php echo esc_html__( 'Award Badges', 'mycred' ); ?></strong></h4>
                        <table>
                            <tbody>
                                <tr>
                                    <th scope="col" id="award-badge" class="manage-column column-name column-primary">
                                        <label>
                                            <?php echo esc_html__( 'Select Badge to Award Manually : ', 'mycred' ); ?>
                                        </label>
                                    </th>
                                    <td> 
                                        <?php
                                        if ( ! empty( get_terms('mycred_badge_plus_type') ) ) {

                                            $terms = get_terms('mycred_badge_plus_type');
                                            
                                            $pages = array(
                                                '-1' => 'Select Badges'
                                            );
                                            
                                            foreach( $terms as $key => $value ) {

                                                $post = get_posts(array(
                                                  'post_type' => 'mycred_badge_plus',
                                                  'numberposts' => -1,
                                                  'tax_query' => array(
                                                    array(
                                                      'taxonomy' => $value->taxonomy,
                                                      'field' => 'term_id',
                                                      'terms' => $value->term_id
                                                  )
                                                )
                                              ));

                                                $ids_title = array();
                                                foreach( $post as $keys => $post_object ) {

                                                    $ids_title[$post_object->ID] = $post_object->post_title;                                        
                                                }

                                                $pages[$key] = array(
                                                    'label' => $value->name,
                                                    'options' => $ids_title
                                                );

                                            }
                                            $atts = array(
                                                'class' => 'mycred-assign-badge-plus'
                                            );
                                            mycred_create_select_field( $pages, array(), $atts );
                                        } ?>
                                    </td>
                                    <td>
                                        <button class="button button-primary assign-reward" data-attr="<?php echo esc_attr( $user_id ); ?>" type="button"><?php echo esc_html__( 'Assign Badge', 'mycred' ); ?></button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <hr><?php
                } 

            }

    /**
     * revoke user badge
     * @since 2.5
     * @version 1.0
     */
    public function mycred_revoke_user_badge() {

        if( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'mycred-badge-plus-nonce' ) ) {
            $badge_id           = isset( $_POST['postid'] ) ? absint( $_POST['postid'] ) : 0;
            $user_id            = isset( $_POST['user_id'] ) ? absint( $_POST['user_id'] ) : 0;
            $earned             = isset( $_POST['earned'] ) ? absint( $_POST['earned'] ) : 0;
            $users_badges       = mycred_get_users_earned_badge_plus( $user_id );
            
            if( in_array( $earned, $users_badges ) ) {

                $badge = mycred_badge_plus_object($badge_id);
                $badge->divest( $user_id, $earned );
                $msg = 'removed';
            }else{
                $msg = 'no badge';
            }

        }

        wp_send_json( array(
            'earned'  => $earned,
            'removed'   => $msg
        ), 200 );

    }
    
    /**
     * assign user badge
     * @since 2.5
     * @version 1.0
     */
    public function mycred_assign_user_badge() {

        // Verify nonce
        if ( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'mycred-badge-plus-nonce' ) ) { 

            // Extract data
            $badge_id = isset( $_POST['postid'] ) ? absint( $_POST['postid'] ) : 0;
            $user_id  = isset( $_POST['user_id'] ) ? absint( $_POST['user_id'] ) : 0;

            if ( ! $badge_id || ! $user_id ) {
                wp_send_json_error( array( 'message' => 'Missing badge or user information.' ), 400 );
            }

            // Get badge object
            $badge = mycred_badge_plus_object( $badge_id );

            if ( ! $badge ) {
                wp_send_json_error( array( 'message' => 'Invalid badge.' ), 404 );
            }

            // Assign badge
            $title  = $badge->title;
            $amount = $badge->points_award;
            $date   = wp_date( 'F d Y h:i A', time() );
            $msg    = 'assign';

            // Handle reassignment
            if ( $badge->user_has_badge( $user_id, $badge_id ) ) {
                return;
                
            }

            $badge->assign( $user_id, $badge_id );

        }

        // Return success response
        wp_send_json_success( array(
            'badge_id' => $badge_id,
            'user_id'  => $user_id,
            'earned'   => time(),
            'title'    => $title,
            'amount'   => $amount,
            'date'     => $date,
            'assign'   => $msg
        ), 200 );
        
    }

    public function balance_adjustment( $result, $request, $mycred ) {

        // If the result was declined
        if ( $result === false ) return $result;

        extract( $request );
        
        if ( $ref == 'badge_plus_reward' ) return $result;
        
        $badge_ids      = mycred_badge_plus_ids_requirements();
        $badge_events   = mycred_get_badge_events();
        
        foreach ( $badge_ids as $key => $values ) {

            $badge    = mycred_badge_plus_object( $values->ID );
            $check_badge = mycred_bp_badges_user_exceeded_max_earnings( $badge, $user_id, $values->ID );
            
            if ( $check_badge ) {

                $badge_id = $values->ID;

                if( ! empty( unserialize( $values->meta_value )['requirements'] ) ) {

                    $check_requirements = array();
                    
                    foreach ( unserialize( $values->meta_value )['requirements'] as $key => $value ) {

                        if ( $value['required'] == 'optional' ) {

                            $check_requirements[] = true;
                            continue;

                        }

                        $requirement_class = new $badge_events[ $value['reference'] ]['class']();
                        $current_requirement_status = (bool) $requirement_class->has_met( $user_id, $value, $badge_id );
                        $check_requirements[] = $current_requirement_status;

                    }

                }
                if ( ! in_array( false, $check_requirements ) ) {
                    $badge->assign( $user_id, $badge_id );

                }
            }

        }
        
        return $result;

    }

    public function earners_page() {


        if ( isset( $_GET['badge_id'] ) ) {

            $temp_earners_count = 1020;
            $limit = 10;
            $page_no = empty( $_GET['page_no'] ) ? 1 : absint( $_GET['page_no'] );

            $badge_id = absint( $_GET['badge_id'] );
            $badge    = mycred_badge_plus_object( $badge_id );
            
            $badge->get_user_count( $badge_id );
            if ( empty( $badge ) || empty( $badge->post_id ) || empty( $badge->type->term_id ) ) return;

            $badge_title = '';

            $earners_count =  $badge->get_user_count( $badge_id ) . ( $badge->get_user_count( $badge_id ) < 2 ? " user" : " users" );

            $total_pages = ceil( $badge->get_user_count( $badge_id ) / $limit );

            $pageurl = add_query_arg( array( 
                'post_type' => 'mycred_badge_plus',
                'page' => 'badge_earners',
                'badge_id' => $badge_id
            ), admin_url('edit.php') );

            if ( ! empty( $badge->title ) ) $badge_title = $badge->title;

            $search_val = '';

            if ( ! empty( $_GET['badge_earner_s'] ) ) 
                $search_val = sanitize_text_field( wp_unslash( $_GET['badge_earner_s'] ) );

            ?>
            <div class="wrap" id="myCRED-wrap">
                <div class="alignleft">
                    <h1><?php echo esc_html( $badge_title . ' (#'. $badge->post_id .')' );?></h1>
                </div>
                <div class="alignright">
                    <a href="<?php echo esc_url( admin_url('edit.php?post_type=mycred_badge_plus') );?>"><?php echo esc_html__( 'Back to Badge Plus', 'mycred' ); ?></a>
                </div>

                <div class="tablenav top">
                    <div class="alignleft actions">
                        <form method="get" action="<?php echo esc_attr( admin_url('edit.php') );?>">
                            <input type="hidden" name="post_type" value="<?php echo esc_attr( MYCRED_BADGE_PLUS_KEY );?>">
                            <input type="hidden" name="page" value="badge_earners">
                            <input type="hidden" name="badge_id" value="<?php echo esc_attr( $badge_id );?>">
                            <input type="search" class="form-control" name="badge_earner_s" value="<?php echo esc_attr( $search_val );?>" size="22" placeholder="User ID, Username or Email">
                            <input type="submit" class="btn btn-default button button-secondary" value="Search">
                        </form>
                    </div>

                    <?php if ( empty( $search_val ) ) :?>

                        <h2 class="screen-reader-text"><?php echo esc_html__( 'Badge earners list navigation', 'mycred' ); ?></h2>
                        <div class="tablenav-pages">
                            <span class="displaying-num"><?php echo esc_html( $earners_count ); ?></span>
                            <?php if ( $badge->get_user_count( $badge_id ) > $limit ) :?>
                                <span class="pagination-links">
                                    <?php if ( $page_no != 1 ) :?>
                                        <a class="last-page button" href="<?php echo esc_url( $pageurl );?>">
                                            <span class="screen-reader-text"><?php echo esc_html__( 'First page', 'mycred' ); ?></span>
                                            <span aria-hidden="true">«</span>
                                        </a>
                                        <a class="next-page button" href="<?php echo esc_url( add_query_arg( 'page_no', ( $page_no - 1 ), $pageurl ) );?>">
                                            <span class="screen-reader-text"><?php echo esc_html__( 'Previous page', 'mycred' ); ?></span>
                                            <span aria-hidden="true">‹</span>
                                        </a>
                                    <?php else:?>
                                        <span class="tablenav-pages-navspan button disabled" aria-hidden="true">«</span>
                                        <span class="tablenav-pages-navspan button disabled" aria-hidden="true">‹</span>
                                    <?php endif;?>
                                    <span class="paging-input">
                                        <label for="current-page-selector" class="screen-reader-text"><?php echo esc_html__( 'Current Page', 'mycred' ); ?></label>
                                        <input class="current-page" type="text" name="paged" value="<?php echo esc_attr( $page_no ); ?>" size="1">
                                        <span class="tablenav-paging-text"> <?php echo esc_html__( 'of', 'mycred' ); ?><span class="total-pages"><?php echo esc_html( $total_pages ); ?></span></span>
                                    </span>
                                    <?php if ( $page_no != $total_pages ) :?>
                                        <a class="next-page button" href="<?php echo esc_url( add_query_arg( 'page_no', ( $page_no + 1 ), $pageurl ) );?>">
                                            <span class="screen-reader-text"><?php echo esc_html__( 'Next page', 'mycred' ); ?></span>
                                            <span aria-hidden="true">›</span>
                                        </a>
                                        <a class="last-page button" href="<?php echo esc_url( add_query_arg( 'page_no', $total_pages, $pageurl ) );?>">
                                            <span class="screen-reader-text"><?php echo esc_html__( 'Last page', 'mycred' ); ?></span>
                                            <span aria-hidden="true">»</span>
                                        </a>
                                    <?php else:?>
                                        <span class="tablenav-pages-navspan button disabled" aria-hidden="true">›</span>
                                        <span class="tablenav-pages-navspan button disabled" aria-hidden="true">»</span>
                                    <?php endif;?>
                                </span>
                            <?php endif;?>
                        </div>
                    <?php endif;?>

                    <br class="clear">
                </div>
                <table class="wp-list-table widefat fixed striped table-view-list posts">
                    <thead>
                        <tr>
                            <th scope="col"><?php echo esc_html__( 'Username', 'mycred' ); ?></th>  
                            <th scope="col"><?php echo esc_html__( 'Earns', 'mycred' ); ?></th>  
                        </tr>
                    </thead>
                    <tbody id="the-list">
                        <?php 
                        
                        $users_args = array( 
                            'fields'        => array( 'ID', 'display_name' ),
                            'meta_key'      => 'mycred_badge_plus'.$badge_id
                        );

                        if ( ! empty( $search_val ) ) {

                            $users_args['search'] = '*' . $search_val . '*';
                            $users_args['search_columns'] = array( 'user_login', 'user_email', 'ID' );

                        }
                        else {

                            $users_args['offset'] = ( ( $page_no - 1 ) * $limit );
                            $users_args['number'] = $limit;

                        }

                        $users = get_users( $users_args );
                        if ( ! empty( $users ) ) {

                            foreach ( $users as $user ) {
                                $user_avatar = get_avatar_url( $user->ID );
                                $profile_url = add_query_arg( 'user_id', $user->ID, admin_url('user-edit.php') ); ?>
                                <tr>
                                    <td class="column-username">
                                        <img width="50" height="50" src="<?php echo esc_url( $user_avatar );?>" class="attachment-50x50 size-50x50 wp-post-image" alt="" loading="lazy">
                                        <h1>
                                            <a class="row-title" href="<?php echo esc_url( $profile_url );?>">

                                                <?php echo esc_html( $user->display_name );?>
                                            </a>
                                        </h1>
                                    </td>
                                    <td style="vertical-align:middle;"><?php echo esc_html( mycred_count_users( $user->ID, $badge_id ) );?></td>

                                </tr>
                                <?php
                                
                            }

                        }
                        else {

                            ?>
                            <tr>
                                <td class="column-username" colspan="2">
                                    <?php echo esc_html__( 'Empty', 'mycred' ); ?>
                                </td>
                            </tr>
                            <?php
                        }

                        ?>
                    </tbody>
                    <tfoot>
                        <tr>
                            <th scope="col"><?php echo esc_html__( 'Username', 'mycred' ); ?></th>
                            <th scope="col"><?php echo esc_html__( 'Earns', 'mycred' ); ?></th>
                        </tr>
                    </tfoot>
                </table>
            </div>
            <?php
        }
        else {

            $url = esc_url(
                add_query_arg(
                    'post_type',
                    'mycred_badge_plus',
                    admin_url( 'edit.php' )
                )
            );

            wp_enqueue_script( 'mycred-badge-plus-admin' );
            
            wp_add_inline_script(
                'mycred-badge-plus-admin',
                'location.href="' . esc_url( $url ) . '"',
                'after'
            );

        }

    }

}
endif;

