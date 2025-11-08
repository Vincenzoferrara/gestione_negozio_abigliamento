<?php
if ( ! defined( 'ABSPATH' ) ) exit;


/**
 * myCRED_Badge class
 * @see http://codex.mycred.me/classes/mycred_badge/
 * @since 1.0.0
 * @version 1.0.0
 */
if ( ! class_exists( 'myCRED_Badge_plus' ) ) :
	class myCRED_Badge_plus extends myCRED_Object {

		protected $user_meta_key   = '';
		public $post_id            = false;
		public $post 			   = false;

		public $title              = 0;
		public $earned             = 0;
		public $open_badge         = false;
		public $main_image         = false;
		public $main_image_url     = false;

		public $image_width        = false;
		public $image_height       = false;

		public $point_types        = array();

		public $user_id            = false;
		
		public $required_steps 	   = '';
		public $user_earned 	   = '';
		public $global_earned	   = '';
		public $points_award 	   = '';
		public $congratulation_msg = '';
		public $requirement		   = '';

		// public $align              = 'mycred_align_left';
		// public $layout             = 'mycred_layout_left';

		/**
		 * Construct
		 */
		function __construct( $badge_id = NULL ) {

			parent::__construct();
			
			if ( is_numeric( $badge_id ) && mycred_get_post_type( $badge_id ) == MYCRED_BADGE_PLUS_KEY )
				$this->post_id = absint( $badge_id );

			else return false;

			$this->user_meta_key = MYCRED_BADGE_PLUS_KEY . $this->post_id;

			$this->populate( $badge_id );

		}

		/**
		 * Populate
		 * @since 1.0
		 * @version 1.0
		 */
		protected function populate( $badge_id = NULLL ) {

			if ( $this->post_id === false ) return;

			$post = mycred_get_post( $badge_id );
			$this->post = $post;
			$this->requirement = mycred_get_post_meta( $this->post_id, 'mycred_badge_requirements', true );

			// Get base badge details
			$this->title        = ( isset( $post->post_title ) ) ? $post->post_title : mycred_get_the_title( $this->post_id );
			$this->earned       =  mycred_get_post_meta( $this->post_id, 'earned-users-with-badge-plus', true );

			// Indicate open badge

			if ( absint( mycred_get_post_meta( $this->post_id, 'mycred_badge_plus_open_badge', true ) ) === 1 ) {

				$badge_setting = mycred_get_option( 'mycred_pref_core' );

				if ( isset( $badge_setting['open_badge'] ) && absint( $badge_setting['open_badge']['is_enabled'] ) === 1 ) {
					
					$this->open_badge = true;

				}
			}

			// Get images
			$this->main_image         = get_post_thumbnail_id( $this->post_id );
			$this->main_image_url	  = $this->get_image_url( 'main' );

			$type = get_the_terms( $this->post_id, 'mycred_badge_plus_type' );

			if ( ! empty( $type[0]->slug ) )
				$this->type = $type[0];

			$this->congratulation_msg = mycred_get_post_meta( $this->post_id, 'congrats_msg', true );
			$this->required_steps 	  = mycred_get_post_meta( $this->post_id, 'complete_steps', true );
			$this->user_earned        = mycred_get_post_meta( $this->post_id, 'mycred_user_badge_plus', true );
			$this->global_earned      = mycred_get_post_meta( $this->post_id, 'mycred_global_badge_plus', true );
			$this->points_award		  = mycred_get_post_meta( $this->post_id, 'mycred_points_badge_plus' ,true );


		}

		/**
		 * Get User Count
		 * @since 1.0.0
		 * @version 1.0.0
		 */
		public function get_user_count( $badge_id = NULL ) {

			if ( $this->post_id === false ) return 0;

			if ( $badge_id !== NULL ) {

				global $wpdb;

				$badge_filter = ( $badge_id !== NULL && is_numeric( $badge_id ) ) ? $wpdb->prepare( "AND meta_value = %s", $badge_id ) : '';
				
				$count = $wpdb->get_var( 
					$wpdb->prepare( 
						"SELECT COUNT( DISTINCT user_id ) FROM %i WHERE meta_key = %s {$badge_filter};",
						$wpdb->usermeta,
						mycred_get_meta_key( $this->user_meta_key ) 
					) 
				);

				if ( $count === NULL ) $count = 0;

			}

			return apply_filters( 'mycred_count_users_with_badge_plus', absint( $count ), $this->post_id );

		}

		/**
		 * User Has Badge
		 * @since 1.0
		 * @version 1.0
		 */
		public function user_has_badge( $user_id = false, $badge_id = 0 ) {

			$has_badge = false;
			if ( $user_id === false ) return $has_badge;
			
			$badge_id = absint( $badge_id );
 	
            $current_badge = mycred_get_user_meta( $user_id, MYCRED_BADGE_PLUS_KEY . $badge_id, '', true );

            if ( ! empty( $current_badge ) )
	                $has_badge = true;


			return apply_filters( 'mycred_user_has_badge_plus', $has_badge, $user_id, $this->post_id );

		}


		/**
		 * Assign Badge to User
		 * @since 1.0
		 * @since 2.3 Added functions `mycred_update_user_meta`, `mycred_get_user_meta` with `mycred_badge_ids`
		 * @version 1.0
		 */
		public function assign( $user_id = false, $badge_id = 0 ) {

		    if ( $user_id === false || absint( $user_id ) === 0 ) return false;

		    $new_badge = $badge_id;
		    $this->user_id = $user_id;

		    // Always increase earned count (whether first or multiple times)
		    $count = mycred_get_post_meta( $badge_id, 'earned-users-with-badge-plus', true );
		    $this->earned = (int) $count + 1;
		    mycred_update_post_meta( $badge_id, 'earned-users-with-badge-plus', $this->earned );

		    $execute = apply_filters( 'mycred_badge_plus_assign', true, $user_id, $new_badge, $this );

		    if ( $execute ) {

		        mycred_update_user_meta( $user_id, $this->user_meta_key, '', $badge_id );

		        $badge_ids = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );

		        if ( empty( $badge_ids ) ) {
		            $badge_ids = array();
		        }

		        if ( empty( $badge_ids[$this->post_id] ) ) {
		            $badge_ids[$this->post_id] = array();
		        }

		        $badge_ids[$this->post_id][] = time(); // multiple timestamps show multiple earns

		        mycred_update_user_meta( $user_id, 'mycred_badge_plus_ids', '', $badge_ids );

		        // ✅ Always payout reward
		        $this->payout_reward( $new_badge );

		        do_action( 'mycred_after_badge_plus_assign', $user_id, $this->post_id, $new_badge );
		    }

		    return true;
		}

		/**
		 * Get Level Reward
		 * @since 1.0
		 * @version 1.0
		 */
		public function get_level_reward( $level_id = false ) {


			if ( $level_id === false || empty( $level_id ) ) return false;


			return $award = array( 
				'amount' => mycred_get_post_meta( $level_id, 'mycred_points_badge_plus' ,true ), 
				'type'			=> mycred_get_post_meta( $level_id, 'point_type' ,true ),
				'log'			=> 'Badge Plus' // mycred_get_post_meta( $this->post_id, 'mycred_log_badge_plus' ,true );
			);
			
		}

		

		/**
		 * Payout Rewards
		 * @since 1.0
		 * @version 1.0
		 */
		public function payout_reward( $new_level ) {

			// Earning the badge
			if ( $new_level ) {

				$reward = $this->get_level_reward( $new_level );

				if ( $reward === false || $reward['log'] == '' || $reward['amount'] == 0 ) {
				    return false; // nothing to give
				}


				$mycred = mycred( $reward['type'] );


				$exec = apply_filters( 'customize_mycred_badge_condition', true, $this->post_id, $this->user_id, $reward['type']);


				if( $exec ) {

					$mycred->add_creds(
						'badge_plus_reward',
						$this->user_id,
						$reward['amount'],
						$reward['log'],
						$this->post_id,
						0,
						$reward['type']
					);

					do_action( 'mycred_badge_plus_reward', $this->user_id, $new_level, $reward, $this );

				}

			}

			return true;

		}

		/**
		 * Divest Badge from user
		 * @since 1.0
		 * @since 2.3 Added functions `mycred_update_user_meta` with `mycred_badge_ids`
		 * @version 1.0
		 */
		public function divest( $user_id = false, $earned = 0 ) {

			if ( $user_id === false || absint( $user_id ) === 0 ) return false;

			$usermeta = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );
			$key = array_search ( $earned, $usermeta[$this->post_id] );
		
			if ( isset(  $usermeta[$this->post_id][$key] ) && count( $usermeta[$this->post_id] ) > 1 ){
				unset(  $usermeta[$this->post_id][$key] );
			}else{
				mycred_delete_user_meta( $user_id, $this->user_meta_key );
				unset(  $usermeta[$this->post_id] );
			}

			$this->earned --;
			if ( $this->earned < 0 ) $this->earned = 0;

			mycred_update_post_meta( $this->post_id, 'earned-users-with-badge-plus', $this->earned );
			mycred_update_user_meta( $user_id, 'mycred_badge_plus_ids', '', $usermeta );

			return true;

		}

		public function display_badge( $atts, $user_id = NULL, $echo = false ) {

	        if ( empty( $this->post_id ) ) return;

	        extract( $atts );

	        if( empty( $badge_id ) )
	        	$badge_id = $this->post_id;

			wp_enqueue_style( 'mycred-badge-shortcode' );

			$user_has_badge = $this->user_has_badge( $user_id, $badge_id );

	        if ( 
	        	( ! empty( $excerpt ) && $excerpt == 1 ) || 
	        	( ! empty( $requirements ) && $requirements == 1 ) || 
	        	( ! empty( $earners ) && $earners == 1 )
	        ) {

	        	$html  = '<div class="mycred-badge">';

	        	if ( ! empty( $image ) && $image == 1 ) 
					$html .= $this->display_image( $image_size, $user_has_badge, $user_id );

				$html .= '<div class="mycred-badge-detail">';

				if ( ! empty( $title ) && $title == 1 ) 
					$html .= $this->display_title( $title_link );

				if ( ! empty( $excerpt ) && $excerpt == 1 ) 
					$html .= $this->display_excerpt();
	
				if ( ! empty( $requirements ) && $requirements == 1 ) 
					$html .= $this->display_requirements( $user_id, $user_has_badge );
	
				if ( ! empty( $earners ) && $earners == 1 ) 
					$html .= $this->display_earners( $user_has_badge, $earners_limit );

				$html .= '</div>';
				$html .= '</div>';

	        }
	        else {

	        	$html  = '<div class="mycred-badge basic">';
	        	
	        	if ( ! empty( $image ) && $image == 1 ) 
					$html .= $this->display_image( $image_size, $user_has_badge, $user_id );
				
				$html .= '<div class="mycred-badge-detail">';
				
				if ( ! empty( $title ) && $title == 1 ) 
					$html .= $this->display_title( $title_link );

				$html .= '</div>';
				$html .= '</div>';

	        }

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

	    public function display_image( $image_size = 80, $user_has_badge = false, $user_id = 0, $echo = false ) {

	        if ( empty( $this->post_id ) ) return;

	        $html  = '<div class="mycred-badge-image">';

	        $img_attr = null;

	    	if ( ! $user_has_badge ) 
	    		$img_attr = array( 'class' => 'mycred-not-earned' );

	    	if ( $image_size < 1 )
	    		 $image_size = 80;
	    		
			if( $this->open_badge && $user_has_badge ){
			    $html .= 
			    		'<div class="badge-plus-image-wrap">
                         	<img height="'. esc_attr( $image_size ) .'" width="'. esc_attr( $image_size ) .'" class="'. esc_attr( $img_attr ) .'" src="'. esc_url( $this->get_earned_image( $user_id ) ) .'" alt />
                        </div>';
        	}else{
        		$html .= wp_kses_post( $this->get_logo_image( absint( $image_size ), $img_attr ) );
        	}

	        $html .= '</div>';

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

	    public function display_title( $link = false, $echo = false ) {

	        if ( empty( $this->post_id ) ) return;

	        $html  = '<h3 class="mycred-badge-title">';

	        if ( $link )
	        	$html .= '<a href="' . esc_url( get_permalink( $this->post_id ) ) . '">' . esc_html( $this->title ) . '</a>';
	        else
	        	$html .= esc_html( $this->title );

	        $html .= '</h3>';

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

	    public function display_excerpt( $echo = false ) {

	        if ( empty( $this->post_id ) ) return;

	        $html = '<p class="mycred-badge-excerpt">' . esc_html( $this->post->post_excerpt ) . '</p>';

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

	    /**
		 * Get badge Logo
		 * Returns the given badges logo.
		 * @since 1.5
		 * @version 1.0
		 */
		public function get_logo_image( $size = 'post-thumbnail', $attr = NULL ) {

			if ( is_numeric( $size ) )
				$size = array( $size, $size );

			if ( mycred_override_settings() && ! mycred_is_main_site() ) {

				switch_to_blog( get_network()->site_id );

				$logo = get_the_post_thumbnail( $this->post, $size, $attr );

				restore_current_blog();

			}
			else {

				$logo = get_the_post_thumbnail( $this->post, $size, $attr );

			}

			return apply_filters( 'mycred_get_badge_plus_logo_image', $logo, $this->post, $size, $attr );

		}

		public function display_requirements( $user_id = NULL, $user_has_badge = false, $echo = false ) {
	        
	        if ( empty( $this->post_id ) || empty( $this->requirement['requirements'] ) ) return;

			$badge_events  = mycred_get_badge_events();
        	$list_element = empty( $this->requirement['is_sequential'] ) ? 'ul' : 'ol';
        	$user_marks   = array();

            if ( ! $user_has_badge ) {
                
                $user_marks = mycred_get_user_meta( $user_id, 'mycred_badge_requirement_', $this->post_id, true );

            }

            $html  = '<h6>'. __( 'Requirements', 'mycred' ) .'</h6>';
            $html .= '<'. $list_element .' class="mycred-badge-requirements">';

            foreach ( $this->requirement['requirements'] as $key => $requirement ) {

                $label = ! empty( $requirement['label'] ) ? $requirement['label'] : 'No Label';
                $required = $requirement['required'];

                $li_class = '';

                if ( $user_has_badge || ! empty( $user_marks ) && in_array( $requirement, $user_marks ) ) {
                    
                    $li_class = ' class="mycred-strike-off"';

                }
                else {

                    $requirement_class = new $badge_events[ $requirement['reference'] ]['class']();

                    if ( (bool) $requirement_class->has_met( $user_id, $requirement, $this->post_id ) ) {
                        
                        $user_marks = mycred_mark_badge_requirement( $user_id, $this->post_id, $requirement );
                        $li_class = ' class="mycred-strike-off"';

                    }

                }

                $html .= '<li'. $li_class .'>';

                if ( ! empty( $requirement['url'] ) ) {
                    
                    $html .= '<a href="'. esc_url( $requirement['url'] ) .'">'. esc_html( $label ) .'</a>' .' ( '. esc_html( $required ) . ' )';

                }
                else {

                    $html .= esc_html( $label ) .' ( '. esc_html( $required ) . ' )';

                }
                $html .= '</li>';

            }

            $html .= '</'. $list_element .'>';

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

	    public function display_earners( $user_has_badge = false, $limit = 10, $display_name = false, $echo = false ) {

	        if ( empty( $this->post_id ) ) return;

			$users_args = array( 
		        'fields' => array( 'ID', 'display_name' ),
		        'meta_key' => 'mycred_badge_plus' . $this->post_id,  
		        'meta_value' => $this->post_id,
		        'number' => absint( $limit )
		    );

		    $earners_list = get_users( $users_args );

		    if ( empty( $earners_list ) ) return 'No user has earned this badge.';

	        $html  = '<h6>' . __( 'People who earned this:', 'mycred' ) . '</h6>';
	        $html .= '<ul class="mycred-badge-earners">';

	        foreach ( $earners_list as $earner ) {
	        	
	        	$html .= '<li>';
	        	$html .= '<img src="'. esc_url( get_avatar_url( $earner->ID ) ) .'" alt="'. esc_html( $earner->display_name ) .'" title="'. esc_html( $earner->display_name ) .'">';

	        	if ( $display_name )
	        		$html .= '<p>'. esc_html( $earner->display_name ) . '</p>';
	        	
	        	$html .= '</li>';
	        	
	        }

	        $html .= '</ul>';

        	if ( $echo ) 
        		echo wp_kses_post( $html );
        	else
        		return $html;

	    }

		/**
		 * Delete Badge
		 * @since 1.0
		 * @version 1.0
		 */
		public function delete( $delete_post = false ) {

			if ( $this->post_id === false ) return false;

			$this->divest_all();

			if ( ! empty( $this->point_types ) ) {

				foreach ( $this->point_types as $point_type )
					mycred_delete_option( 'mycred-badge-references-' . $point_type );

			}

			if ( $delete_post )
				mycred_delete_post( $this->post_id, true );

			return true;

		}

		/**
		 * Get Badge Image
		 * @since 1.0
		 * @version 1.1
		 */
		public function get_image( $image = NULL ) {

			$image_identification = false;

			$image_url    = $this->get_image_url( $image );

			$image_width  = ( $this->image_width !== false ) ? ' width="' . esc_attr( $this->image_width ) . '"' : '';
			$image_height = ( $this->image_height !== false ) ? ' height="' . esc_attr( $this->image_height ) . '"' : '';

			if ( ! $image_url ) return false;

			$html         = '<img src="' . esc_url( $image_url ) . '" class="' . MYCRED_SLUG . '-badge-plus-image ' . '" alt="' . esc_attr( $this->title ) . '"' . $image_width . $image_height . ' />';

			return apply_filters( 'mycred_badge_image', $html, $image, $this );

		}

		public function get_image_url( $image = NULL ) {

			$image_identification = false;

			if ( $image === 'main' )
				$image_identification = mycred_get_attachment_url( $this->main_image );


			if ( $image_identification === false || strlen( $image_identification ) == 0 ) return false;

			$image_url = $image_identification;

			return apply_filters( 'mycred_badge_plus_image_url', $image_url, $image, $this );

		}

		public function get_earned_image( $user_id ) {

			$image_url = $this->main_image_url;

			if ( $this->open_badge && $this->user_has_badge( $user_id, $this->post_id ) ) {

				$wp_upload_dirs = wp_upload_dir();
				$basedir = trailingslashit( $wp_upload_dirs[ 'basedir' ] );
				$baseurl = trailingslashit( $wp_upload_dirs[ 'baseurl' ] );

				$folderName = apply_filters( 'mycred_open_badge_folder', 'open_badges' );

				$open_badge_directory = $basedir . $folderName;

				$open_badge_directory = trailingslashit( $open_badge_directory );

				$badge_id = $this->post_id;

				$filename = "badge-{$badge_id}-{$user_id}.png";
				
				if ( ! file_exists( $open_badge_directory . $filename ) ) {

					$mycred_Open_Badge = new mycred_Open_Badge();
					$mycred_Open_Badge->bake_users_image( $user_id, $badge_id, $image_url, $this->title, $this->open_badge );

				}

				$image_url = trailingslashit( $baseurl . $folderName ) . $filename;

			}

			return $image_url;

		}

	}
endif;