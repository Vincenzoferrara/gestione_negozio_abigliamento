<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'myCRED_Ranks_Plus_Module' ) ) :
	class myCRED_Ranks_Plus_Module extends myCRED_Module {

		/**
		 * Construct
		 */
		public function __construct() {

			parent::__construct(
				'myCRED_Ranks_Plus_Module',
				array(
					'module_name' => 'rank_plus',
					'defaults'    => array(),
					'register'    => false,
				)
			);
		}

		/**
		 * Load
		 * Custom module load for multiple point type support.
		 *
		 * @since 1.6
		 * @version 1.0
		 */
		public function load() {

			add_action( 'mycred_pre_init', array( $this, 'module_pre_init' ) );
			add_action( 'mycred_init', array( $this, 'module_init' ) );
			add_action( 'mycred_admin_init', array( $this, 'module_admin_init' ), $this->menu_pos );

			require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'mycred-rank-object.php';
			require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'blocks/mycred-rank-specific-blocks.php';
			require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'mycred-abstract-rank-requirement.php';
			require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'mycred-rank-plus-shortcodes.php';
			require_once MYCRED_RANK_PLUS_REQUIREMENTS_DIR . 'mycred-rank-default-requirement.php';
			require_once MYCRED_RANK_PLUS_REQUIREMENTS_DIR . 'mycred-rank-registration-requirement.php';
			require_once MYCRED_RANK_PLUS_REQUIREMENTS_DIR . 'mycred-rank-link-click-requirement.php';
			require_once MYCRED_RANK_PLUS_REQUIREMENTS_DIR . 'mycred-rank-balance-reached-requirement.php';
			require_once MYCRED_RANK_PLUS_REQUIREMENTS_DIR . 'mycred-rank-earned-points-amount-requirement.php';
		}

		/**
		 * Hook into Init
		 *
		 * @since 1.4.4
		 * @version 1.0.2
		 */
		public function module_pre_init() {

			add_filter( 'mycred_add_finished', array( $this, 'balance_adjustment' ), 20, 3 );
			add_action( 'user_register', array( $this, 'assign_default_ranks' ), 9 );
			add_filter( 'mycred_post_type_excludes', array( $this, 'exclude_ranks' ) );
		}

		/**
		 * Hook into Init
		 *
		 * @since 1.1
		 * @version 1.5
		 */
		public function module_init() {

			mycred_rank_register_post();
			mycred_rank_register_post_type();

			$this->register_metaboxes();

			add_action( 'admin_enqueue_scripts', array( $this, 'admin_scripts_and_styles' ) );
			add_action( 'mycred_register_assets', array( $this, 'frontend_scripts_and_styles' ) );
			add_submenu_page( '', 'Earners', 'Earners', $this->core->get_point_editor_capability(), 'earners', array( $this, 'earners_page' ) );

			// Shortcodes
			add_shortcode( MYCRED_SLUG . '_rank_plus', 'mycred_render_rank' );
			add_shortcode( MYCRED_SLUG . '_ranks_plus', 'mycred_render_ranks' );
			add_shortcode( MYCRED_SLUG . '_user_ranks', 'mycred_render_user_ranks' );
		}

		/**
		 * Hook into Admin Init
		 *
		 * @since 1.1
		 * @version 1.3
		 */
		public function module_admin_init() {

			add_filter( 'post_row_actions', array( $this, 'adjust_row_actions' ), 10, 2 );
			add_filter( 'post_updated_messages', array( $this, 'post_updated_messages' ) );
			add_filter( 'enter_title_here', array( $this, 'enter_title_here' ) );
			add_action( 'restrict_manage_posts', array( $this, 'filter_by_rank_type' ), 10, 1 );
			add_action( 'wp_ajax_mycred_save_rank_requirements', array( $this, 'save_rank_requirements' ) );
			add_action( 'wp_ajax_mycred_assign_rank_to_eligible_users', array( $this, 'assign_rank_to_eligible_users' ) );
			add_action( 'enqueue_block_editor_assets', array( $this, 'register_block_assets' ) );

			add_filter( 'manage_' . MYCRED_RANK_PLUS_KEY . '_posts_columns', array( $this, 'adjust_column_headers' ), 50 );
			add_action( 'manage_' . MYCRED_RANK_PLUS_KEY . '_posts_custom_column', array( $this, 'adjust_column_content' ), 10, 2 );

			add_action( 'add_meta_boxes', array( $this, 'add_metaboxes' ) );
			add_action( 'mycred_user_edit_after_balances', array( $this, 'show_ranks_in_user_editor' ) );
			add_action( 'save_post_' . MYCRED_RANK_PLUS_KEY, array( $this, 'save_rank' ), 10, 3 );
			add_filter( 'mycred_rank_cache', array( $this, 'adjust_rank_cache' ), 10, 4 );
			add_filter( 'admin_footer-edit-tags.php', array( $this, 'replace_taxonomy_delete_msg' ) );
			add_action( 'delete_' . MYCRED_RANK_TYPE_KEY, array( $this, 'delete_rank_type' ), 10, 4 );
			add_action( 'delete_user', array( $this, 'delete_user_rank_data' ) );
		}

		public function earners_page() {

			if ( isset( $_GET['rank_id'] ) ) {

				$limit   = 10;
				$page_no = empty( $_GET['page_no'] ) ? 1 : absint( $_GET['page_no'] );

				$rank_id = absint( $_GET['rank_id'] );
				$rank    = mycred_rank( $rank_id );

				if ( empty( $rank ) || empty( $rank->rank_id ) || empty( $rank->type->term_id ) ) {
					return;
				}

				$rank_title = '';

				$earners_count = number_format( $rank->earners_count ) . ( $rank->earners_count < 2 ? ' user' : ' users' );

				$total_pages = ceil( $rank->earners_count / $limit );

				$pageurl = add_query_arg(
					array(
						'post_type' => 'mycred_rank_plus',
						'page'      => 'earners',
						'rank_id'   => $rank_id,
					),
					admin_url( 'edit.php' )
				);

				if ( ! empty( $rank->title ) ) {
					$rank_title = $rank->title;
				}

				$search_val = '';

				if ( ! empty( $_GET['earner_s'] ) ) {
					$search_val = sanitize_text_field( wp_unslash( $_GET['earner_s'] ) );
				}

				?>
				<div class="wrap" id="myCRED-wrap">
					<div class="alignleft">
						<h1><?php echo esc_html( $rank_title . ' (#' . $rank->rank_id . ')' ); ?></h1>
					</div>
					<div class="alignright">
						<a href="<?php echo esc_url( admin_url( 'edit.php?post_type=mycred_rank_plus' ) ); ?>">Back to Ranks</a>
					</div>
					<div class="tablenav top">
						<div class="alignleft actions">
							<form method="get" action="<?php echo esc_attr( admin_url( 'edit.php' ) ); ?>">
								<input type="hidden" name="post_type" value="<?php echo esc_attr( MYCRED_RANK_PLUS_KEY ); ?>">
								<input type="hidden" name="page" value="earners">
								<input type="hidden" name="rank_id" value="<?php echo esc_attr( $rank_id ); ?>">
								<input type="search" class="form-control" name="earner_s" value="<?php echo esc_attr( $search_val ); ?>" size="22" placeholder="User ID, Username or Email">
								<input type="submit" class="btn btn-default button button-secondary" value="Search">
							</form>
						</div>
						<?php if ( empty( $search_val ) ) : ?>
						<h2 class="screen-reader-text">Rank earners list navigation</h2>
						<div class="tablenav-pages">
							<span class="displaying-num"><?php echo esc_html( $earners_count ); ?></span>
							<?php if ( $rank->earners_count > $limit ) : ?>
								<span class="pagination-links">
									<?php if ( $page_no != 1 ) : ?>
									<a class="last-page button" href="<?php echo esc_url( $pageurl ); ?>">
										<span class="screen-reader-text">First page</span>
										<span aria-hidden="true">«</span>
									</a>
									<a class="next-page button" href="<?php echo esc_url( add_query_arg( 'page_no', ( $page_no - 1 ), $pageurl ) ); ?>">
										<span class="screen-reader-text">Previous page</span>
										<span aria-hidden="true">‹</span>
									</a>
									<?php else : ?>
										<span class="tablenav-pages-navspan button disabled" aria-hidden="true">«</span>
										<span class="tablenav-pages-navspan button disabled" aria-hidden="true">‹</span>
									<?php endif; ?>
									<span class="paging-input">
										<label for="current-page-selector" class="screen-reader-text">Current Page</label>
										<input class="current-page" type="text" name="paged" value="<?php echo esc_attr( $page_no ); ?>" size="1">
										<span class="tablenav-paging-text"> of <span class="total-pages"><?php echo esc_html( $total_pages ); ?></span></span>
									</span>
									<?php if ( $page_no != $total_pages ) : ?>
									<a class="next-page button" href="<?php echo esc_url( add_query_arg( 'page_no', ( $page_no + 1 ), $pageurl ) ); ?>">
										<span class="screen-reader-text">Next page</span>
										<span aria-hidden="true">›</span>
									</a>
									<a class="last-page button" href="<?php echo esc_url( add_query_arg( 'page_no', $total_pages, $pageurl ) ); ?>">
										<span class="screen-reader-text">Last page</span>
										<span aria-hidden="true">»</span>
									</a>
									<?php else : ?>
										<span class="tablenav-pages-navspan button disabled" aria-hidden="true">›</span>
										<span class="tablenav-pages-navspan button disabled" aria-hidden="true">»</span>
									<?php endif; ?>
								</span>
							<?php endif; ?>
						</div>
						<?php endif; ?>
						<br class="clear">
					</div>
					<table class="wp-list-table widefat fixed striped table-view-list posts">
						<thead>
							<tr>
								<th scope="col">Username</th>
								<th scope="col">Date</th>	
							</tr>
						</thead>
						<tbody id="the-list">
							<?php

								$users_args = array(
									'fields'     => array( 'ID', 'display_name' ),
									'meta_key'   => 'mycred_current_rank_' . $rank->type->term_id,
									'meta_value' => $rank_id,
								);

								if ( ! empty( $search_val ) ) {

									$users_args['search']         = '*' . $search_val . '*';
									$users_args['search_columns'] = array( 'user_login', 'user_email', 'ID' );

								} else {

									$users_args['offset'] = ( ( $page_no - 1 ) * $limit );
									$users_args['number'] = $limit;

								}

								$users = get_users( $users_args );

								if ( ! empty( $users ) ) {
									foreach ( $users as $user ) {

										$user_avatar = get_avatar_url( $user->ID );
										$achived_on  = mycred_get_user_meta( $user->ID, 'mycred_rank_', $rank_id, true );
										$profile_url = add_query_arg( 'user_id', $user->ID, admin_url( 'user-edit.php' ) );

										?>
										<tr>
											<td class="column-username">
												<img width="50" height="50" src="<?php echo esc_url( $user_avatar ); ?>" class="attachment-50x50 size-50x50 wp-post-image" alt="" loading="lazy">
												<h1>
													<a class="row-title" href="<?php echo esc_url( $profile_url ); ?>">
														<?php echo esc_html( $user->display_name ); ?>
													</a>
												</h1>
											</td>
											<td style="vertical-align:middle;"><?php echo esc_html( wp_date( 'F d Y h:i A', $achived_on ) ); ?></td>
										</tr>
										<?php

									}
								} else {
									?>
										<tr>
											<td class="column-username" colspan="2">
												Empty
											</td>
										</tr>
									<?php
								}

								?>
						</tbody>
						<tfoot>
							<tr>
								<th scope="col">Username</th>
								<th scope="col">Date</th>
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
						'mycred_rank_plus',
						admin_url( 'edit.php' )
					)
				);

				wp_enqueue_script( 'mycred-ranks-plus-admin' );
				
				wp_add_inline_script(
					'mycred-ranks-plus-admin',
					'location.href="' . esc_url( $url ) . '"',
					'after'
				);

			}

		}

		/**
		 * Add Admin Menu Item
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function add_metaboxes() {

			add_mycred_meta_box(
				'mycred-rank-requirement',
				__( 'Rank Requirements', 'mycred' ),
				array( $this, 'metabox_rank_setup' ),
				MYCRED_RANK_PLUS_KEY,
				'normal',
				'low',
				'dashicons-chart-bar'
			);
			
		}

		/**
		 * Add Admin Menu Item
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function metabox_rank_setup() {

			wp_enqueue_style( 'mycred-bootstrap-grid' );
			wp_enqueue_style( 'mycred-ranks-plus-admin' );
			wp_enqueue_script( 'mycred-ranks-plus-admin' );
			wp_enqueue_script( MYCRED_SLUG . '-select2-script' );
			wp_enqueue_style( MYCRED_SLUG . '-select2-style' );
			wp_enqueue_style( MYCRED_SLUG . '-buttons' );

			$post_id = get_the_ID();

			$requirements = mycred_get_post_meta( $post_id, 'mycred_rank_requirements', true );
			$is_default   = mycred_get_post_meta( $post_id, 'mycred_rank_plus_is_default', true );

			$is_sequential = isset( $requirements['is_sequential'] ) ? $requirements['is_sequential'] : false;

			wp_nonce_field( 'mrp-nonce', 'mycred-mrp-nonce' );

			?>
			
			<div class="mycred-rank-requirement-inside <?php echo ! empty( $is_default ) ? 'mycred-hide' : ''; ?>">
				
				<p>Define the requirements for this rank that will be considered as criteria for users.</p>
					<div class="mycred-form-group">
					<label for="mrr-sequential"><strong>Sequential Requirements</strong></label>
						<label class="mycred-toggle">
							<input type="checkbox" id="mrr-sequential" <?php checked( $is_sequential, true ); ?>> 
							<span class="slider round"></span>
						</label>
				</div>

				<ul class="mycred-sortable <?php echo $is_sequential ? 'sequence' : ''; ?>" id="mycred-rank-requirements-list">
				<?php

				if ( ! empty( $requirements ) && ! empty( $requirements['requirements'] ) ) {

					$sequence = 1;
					foreach ( $requirements['requirements'] as $requirement ) {

						mycred_rank_requirement_html( $requirement, $sequence );
						++$sequence;

					}
				}

				?>
				</ul>

				<div class="mycred-form-group">
					<button class="button mycred-button-success" id="mycred-add-rank-requirement"><?php esc_html_e( 'Add new Rank Requirement', 'mycred' ); ?></button>
					<button class="button mycred-button-default" id="mycred-save-rank-requirement"><?php esc_html_e( 'Save all Rank Requirements', 'mycred' ); ?></button>
					<span class="mrr-requirement-loader spinner"></span>
				</div>

			</div>

			<p id="mycred-rank-requirement-restriction" class="<?php echo empty( $is_default ) ? 'mycred-hide' : ''; ?>">
				The default rank will be created without any requirements. You will be able to set requirements on the next rank(s). 
			</p>

			<?php

			$mycred_rank_requirement_template = mycred_rank_requirement_html( array(), null, false );

			$rank_events          = mycred_get_rank_events();
			$rank_event_templates = array();

			foreach ( $rank_events as $key => $event ) {

				$requirement_class            = new $event['class']();
				$rank_event_templates[ $key ] = $requirement_class->settings( array(), false );

			}

			wp_localize_script(
				'mycred-ranks-plus-admin',
				'mycred_ranks_plus_localize_data',
				array(
					'requirement_template' => $mycred_rank_requirement_template,
					'event_templates'      => $rank_event_templates,
					'post_id'              => get_the_ID(),
				)
			);
		}

		/**
		 * Save Rank requirement
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function save_rank_requirements() {

			if (
				! current_user_can( 'edit_posts' ) ||
				! isset( $_POST['nonce'] ) ||
				! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'mrp-nonce' ) ||
				! isset( $_POST['postid'] ) ||
				! isset( $_POST['requirements'] ) ||
				! isset( $_POST['is_sequential'] )
			) {
				wp_send_json( 'error' );
			}

			$post_id           = absint( $_POST['postid'] );
			$rank_requirements = mycred_sanitize_array( wp_unslash( $_POST['requirements'] ) );
			$is_sequential     = boolval( $_POST['is_sequential'] );

			$meta = mycred_update_post_meta(
				$post_id,
				'mycred_rank_requirements',
				array(
					'is_sequential' => $is_sequential,
					'requirements'  => $rank_requirements,
				)
			);

			wp_send_json( $meta );
		}

		/**
		 * Save Rank requirement
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function assign_rank_to_eligible_users() {

			if (
				! current_user_can( 'edit_posts' ) ||
				! isset( $_POST['nonce'] ) ||
				! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'mrp-nonce' ) ||
				! isset( $_POST['postid'] )
			) {
				wp_send_json( array( 'result' => 'error' ) );
			}

			$rank_id = absint( $_POST['postid'] );
			$rank    = mycred_rank( $rank_id );

			if ( empty( $rank ) || empty( $rank->type->term_id ) ) {
				wp_send_json( array( 'result' => 'error' ) );
			}

			$meta_query = array(
				array(
					'key'     => 'mycred_current_rank_' . $rank->type->term_id,
					'compare' => 'NOT EXISTS',
				),
			);

			if ( empty( $rank->is_default ) ) {

				$ranks_cache = mycred_get_ranks_cache();

				if ( empty( $ranks_cache['sequence'][ $rank->type->term_id ] ) ) {
					wp_send_json( array( 'result' => 'error' ) );
				}

				$rank_ids   = $ranks_cache['sequence'][ $rank->type->term_id ];
				$rank_index = array_search( $rank_id, $rank_ids );

				if ( empty( $ranks_cache['sequence'][ $rank->type->term_id ][ $rank_index - 1 ] ) ) {
					wp_send_json( array( 'result' => 'error' ) );
				}

				$previous_id = $ranks_cache['sequence'][ $rank->type->term_id ][ $rank_index - 1 ];

				$meta_query = array(
					array(
						'key'     => 'mycred_rank_' . $rank_id,
						'compare' => 'NOT EXISTS',
					),
					array(
						'key'   => 'mycred_current_rank_' . $rank->type->term_id,
						'value' => $previous_id,
					),
				);

			}

			$all_users = get_users(
				array(
					'fields'     => array( 'ID' ),
					'meta_query' => $meta_query,
				)
			);

			$rank_events = mycred_get_rank_events();

			$assign_count = 0;

			foreach ( $all_users as $user ) {

				if ( ! empty( $rank->is_default ) ) {

					$rank->assign( $user->ID );
					++$assign_count;

				} else {

					$check_requirements = array();

					if ( ! empty( $ranks_cache['ranks'][ $rank_id ]['requirements']['requirements'] ) ) {

						$rank_requirements = $ranks_cache['ranks'][ $rank_id ]['requirements']['requirements'];

						foreach ( $rank_requirements as $key => $requirement ) {

							if ( $requirement['required'] == 'optional' ) {

								$check_requirements[] = true;
								continue;

							}

							$requirement_class          = new $rank_events[ $requirement['reference'] ]['class']();
							$current_requirement_status = (bool) $requirement_class->has_met( $user->ID, $requirement );
							$check_requirements[]       = $current_requirement_status;

							if ( ! empty( $next_rank['requirements']['is_sequential'] ) && ! $current_requirement_status ) {
								break;
							}
						}
					}

					if ( ! in_array( false, $check_requirements ) ) {

						$rank->assign( $user->ID );
						++$assign_count;

					}
				}
			}

			$msg = sprintf( __( 'Rank is successfully assigned to %s users.', 'mycred' ), $assign_count );

			if ( empty( $assign_count ) ) {
				$msg = __( 'No eligible user for this rank.', 'mycred' );
			}

			wp_send_json(
				array(
					'result' => 'success',
					'msg'    => $msg,
				)
			);
		}

		public function filter_by_rank_type( $post_type ) {

			if ( MYCRED_RANK_PLUS_KEY !== $post_type ) {
				return;
			}

			$taxonomies = get_taxonomy( MYCRED_RANK_TYPE_KEY );
			$selected   = isset( $_REQUEST[ MYCRED_RANK_TYPE_KEY ] ) ? sanitize_key( $_REQUEST[ MYCRED_RANK_TYPE_KEY ] ) : '';

			wp_dropdown_categories(
				array(
					'show_option_all' => $taxonomies->labels->all_items,
					'taxonomy'        => MYCRED_RANK_TYPE_KEY,
					'name'            => MYCRED_RANK_TYPE_KEY,
					'orderby'         => 'name',
					'value_field'     => 'slug',
					'selected'        => $selected,
					'hierarchical'    => true,
				)
			);
		}

		/**
		 * Adjust Post Updated Messages
		 *
		 * @since 1.1
		 * @version 1.2
		 */
		public function post_updated_messages( $messages ) {

			$messages[ MYCRED_RANK_PLUS_KEY ] = array(
				0  => '',
				1  => __( 'Rank Updated.', 'mycred' ),
				2  => __( 'Rank Updated.', 'mycred' ),
				3  => __( 'Rank Updated.', 'mycred' ),
				4  => __( 'Rank Updated.', 'mycred' ),
				5  => __( 'Rank Updated.', 'mycred' ),
				6  => __( 'Rank Enabled.', 'mycred' ),
				7  => __( 'Rank Saved.', 'mycred' ),
				8  => __( 'Rank Updated.', 'mycred' ),
				9  => __( 'Rank Updated.', 'mycred' ),
				10 => '',
			);

			return $messages;
		}

		/**
		 * Exclude Ranks from Publish Content Hook
		 *
		 * @since 1.3
		 * @version 1.0
		 */
		public function exclude_ranks( $excludes ) {

			$excludes[] = MYCRED_RANK_PLUS_KEY;
			return $excludes;
		}

		/**
		 * Show Rank in User Editor
		 *
		 * @since 1.7
		 * @version 1.3
		 */
		public function show_ranks_in_user_editor( $user ) {

			$user_id    = $user->ID;
			$rank_types = get_terms( 'mycred_rank_types', array( 'hide_empty' => false ) );
			?>
			<hr>
			<style type="text/css">
				.mycred-rank-list { display: flex; flex-wrap: wrap; }
				.mycred-rank-type-wrapper { width: 210px; margin: 0 15px 15px 0; padding: 10px 10px 20px 10px; background-color: #ffffff; box-shadow: 0 0 1px 1px #8c8f9424; }
				.mycred-rank-type-wrapper p { font-size: 12px !important; font-style: italic; text-align: left; }
				.mycred-rank-wrapper { margin-top: 10px; text-align: center; }
				.mycred-rank-wrapper h4 { margin: 0; }
			</style>
			<table class="form-table">
				<tr>
					<th scope="row"><?php esc_html_e( 'Ranks', 'mycred' ); ?></th>
					<td>
						<div class="mycred-rank-list">
							<?php
							if ( ! empty( $rank_types ) ) {
								foreach ( $rank_types as $rank_type ) {

									if ( $rank_type->count > 0 ) {

										$users_rank_id = mycred_get_users_rank_by_type( $user_id, $rank_type->term_id );

										if ( ! empty( $users_rank_id ) ) {

											$users_rank = mycred_rank( $users_rank_id );
											?>
											<div class="mycred-rank-type-wrapper">
												<span><?php echo esc_html( $rank_type->name ); ?></span>
												<div class="mycred-rank-wrapper">
													<?php echo wp_kses_post( $users_rank->get_logo_image( 80 ) ); ?>
													<h4><?php echo esc_html( $users_rank->title ); ?></h4>
												</div>
											</div>
											<?php
										} else {

											// Assign default rank here

										}
									} else {
										?>
										<div class="mycred-rank-type-wrapper">
											<span><?php echo esc_html( $rank_type->name ); ?></span>
											<div class="mycred-rank-wrapper"><p><?php esc_html_e( 'There are no ranks created in this rank type.', 'mycred' ); ?></p></div>
										</div>
										<?php
									}
								}
							}
							?>
						</div>
					</td>
				</tr>
			</table>
			<hr>
			<?php
		}

		/**
		 * Register Scripts & Styles
		 *
		 * @since 1.7
		 * @version 1.0
		 */
		public function admin_scripts_and_styles() {

			wp_register_script(
				'mycred-ranks-plus-admin',
				plugins_url( 'assets/js/admin.js', MYCRED_RANK_PLUS_THIS ),
				array( 'jquery' ),
				MYCRED_RANK_PLUS_VERSION
			);

			wp_register_style(
				'mycred-ranks-plus-admin',
				plugins_url( 'assets/css/admin.css', MYCRED_RANK_PLUS_THIS ),
				array(),
				MYCRED_RANK_PLUS_VERSION
			);
		}

		/**
		 * Register Frontend Scripts & Styles
		 *
		 * @since 1.1
		 * @version 1.3.2
		 */
		public function frontend_scripts_and_styles() {

			wp_register_style(
				'mycred-rank-shortcodes',
				plugins_url( 'assets/css/mycred-rank-shortcodes.css', MYCRED_RANK_PLUS_THIS ),
				array(),
				MYCRED_RANK_PLUS_VERSION
			);
		}

		/**
		 * Adjust Rank Column Header
		 *
		 * @since 1.1
		 * @version 1.2
		 */
		public function adjust_column_headers( $defaults ) {

			$columns       = array();
			$columns['cb'] = $defaults['cb'];

			$columns['title']                = __( 'Rank Title', 'mycred' );
			$columns['mycred-rank-logo']     = __( 'Image', 'mycred' );
			$columns['mycred-rank-type']     = __( 'Rank Type', 'mycred' );
			$columns['mycred-rank-priority'] = __( 'Priority', 'mycred' );
			$columns['mycred-rank-earners']  = __( 'Earners', 'mycred' );
			$columns['date']                 = __( 'Date', 'mycred' );

			// Return
			return $columns;
		}

		/**
		 * Adjust Rank Column Content
		 *
		 * @since 1.1
		 * @version 1.1
		 */
		public function adjust_column_content( $column_name, $post_id ) {

			$rank = mycred_rank( $post_id );

			switch ( $column_name ) {

				case 'mycred-rank-logo':
					if ( ! empty( $rank->logo_id ) ) {
						echo wp_kses_post( $rank->get_logo_image( 50 ) );
					} else {
						esc_html_e( 'No Image Set', 'mycred' );
					}
					break;
				case 'mycred-rank-type':
					if ( ! empty( $rank->type->name ) ) {
						echo esc_html( $rank->type->name );
					}
					break;
				case 'mycred-rank-priority':
					if ( ! empty( $rank->is_default ) ) {
						esc_html_e( 'Default Rank', 'mycred' );
					} elseif ( ! empty( $rank->priority ) ) {
						echo esc_html( $rank->priority );
					}
					break;
				case 'mycred-rank-earners':
					echo esc_html( $rank->earners_count );
					break;
				default:
					break;

			}
		}

		/**
		 * Adjust Row Actions
		 *
		 * @since 1.1
		 * @version 1.0
		 */
		public function adjust_row_actions( $actions, $post ) {

			if ( $post->post_type == MYCRED_RANK_PLUS_KEY ) {

				unset( $actions['inline hide-if-no-js'] );

				$url = add_query_arg(
					array(
						'post_type' => 'mycred_rank_plus',
						'page'      => 'earners',
						'rank_id'   => $post->ID,
					),
					admin_url( 'edit.php' )
				);

				$actions['earners'] = '<a href="' . esc_url( $url ) . '">' . __( 'View Earners', 'mycred' ) . '</a>';

			}

			return $actions;
		}

		/**
		 * Adjust Row Actions
		 *
		 * @since 1.1
		 * @version 1.0
		 */
		public function replace_taxonomy_delete_msg() {

			if ( isset( $_GET['post_type'] ) &&
				isset( $_GET['taxonomy'] ) &&
				$_GET['post_type'] == MYCRED_RANK_PLUS_KEY &&
				$_GET['taxonomy'] == MYCRED_RANK_TYPE_KEY
			) :
				?>
			<script type="text/javascript">

				var mycred_rtd_msg = wp.i18n.__( 'Are you sure you want to delete this Rank Type?\n\nNote: All ranks of this type will also be deleted.\n\'Cancel\' to stop, \'OK\' to delete.' );

				showNotice.warn = function() {
					if ( confirm( mycred_rtd_msg ) ) {
						return true;
					}

					return false;
				};

				jQuery(".taxonomy-mycred_rank_types #doaction").click(function(e){

					if ( jQuery('#bulk-action-selector-top').val() == 'delete' ) {

						e.preventDefault();

						var confirm = true;
						mycred_rtd_msg = wp.i18n.__( 'Are you sure you want to delete the selected rank type(s)?\n\nNote: All ranks of the selected rank type(s) will also be deleted.\n\'Cancel\' to stop, \'OK\' to delete.' );

						if ( 'undefined' != showNotice )
							confirm = showNotice.warn();

						if ( confirm ) {

							jQuery(this).closest('form').submit();

						}

					}

				});

			</script>
			<style type="text/css">
				form#addtag .form-field.term-parent-wrap { display: none; }
			</style>
				<?php
			endif;
		}

		/**
		 * Adjust Enter Title Here
		 *
		 * @since 1.1
		 * @version 1.0
		 */
		public function enter_title_here( $title ) {

			global $post_type;
			if ( $post_type == MYCRED_RANK_PLUS_KEY ) {
				return __( 'Rank Title', 'mycred' );
			}

			return $title;
		}

		public function register_block_assets() {

			global $post;

			if ( $post->post_type == MYCRED_RANK_PLUS_KEY ) {

				wp_register_script(
					'mycred-ranks-plus-meta',
					plugins_url( 'assets/js/metaboxes.js', MYCRED_RANK_PLUS_THIS ),
					array(
						'wp-blocks',
						'wp-element',
						'wp-components',
						'wp-editor',
						'wp-plugins',
						'wp-edit-post',
					),
					MYCRED_RANK_PLUS_VERSION
				);

				wp_localize_script(
					'mycred-ranks-plus-meta',
					'mycred_ranks_plus_meta_data',
					array(
						'rankTypesURL' => add_query_arg(
							array(
								'post_type' => MYCRED_RANK_PLUS_KEY,
								'taxonomy'  => MYCRED_RANK_TYPE_KEY,
							),
							admin_url( 'edit-tags.php' )
						),
					)
				);

				wp_enqueue_script( 'mycred-ranks-plus-meta' );

			}
		}

		/**
		 * Add Meta Boxes
		 *
		 * @since 1.1
		 * @version 1.0
		 */
		public function register_metaboxes() {

			register_post_meta(
				MYCRED_RANK_PLUS_KEY,
				'mycred_rank_plus_priority',
				array(
					'show_in_rest'      => true,
					'single'            => true,
					'type'              => 'number',
					'description'       => __( 'The rank priority defines the order a user can achieve ranks. User will need to get lower priority ranks before get this one.', 'mycred' ),
					'sanitize_callback' => function ( $meta_value ) {
						return absint( $meta_value );
					},
					'auth_callback'     => function () {
						return current_user_can( 'edit_posts' );
					},
				)
			);

			register_term_meta(
				MYCRED_RANK_TYPE_KEY,
				'max_priority',
				array(
					'show_in_rest'      => true,
					'single'            => true,
					'type'              => 'number',
					'sanitize_callback' => function ( $meta_value ) {
						return absint( $meta_value );
					},
					'auth_callback'     => function () {
						return current_user_can( 'edit_posts' );
					},
				)
			);

			register_post_meta(
				MYCRED_RANK_PLUS_KEY,
				'mycred_rank_plus_is_default',
				array(
					'show_in_rest'      => true,
					'single'            => true,
					'type'              => 'boolean',
					'description'       => __( 'Enable to make this rank default of the selected rank type.', 'mycred' ),
					'sanitize_callback' => 'bool',
					'auth_callback'     => function () {
						return current_user_can( 'edit_posts' );
					},
				)
			);

			register_post_meta(
				MYCRED_RANK_PLUS_KEY,
				'mycred_rank_plus_congratulation_msg',
				array(
					'show_in_rest'      => true,
					'single'            => true,
					'type'              => 'string',
					'description'       => __( 'Congratulation Message appears when a user has achieved the rank.', 'mycred' ),
					'sanitize_callback' => function ( $meta_value ) {
						return sanitize_text_field( $meta_value );
					},
					'auth_callback'     => function () {
						return current_user_can( 'edit_posts' );
					},
				)
			);
		}

		/**
		 * Save Rank Details
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function save_rank( $post_id, $post, $update ) {

			$type = get_the_terms( $post_id, 'mycred_rank_types' );

			if ( ! empty( $type[0]->term_id ) ) {

				if ( $post->post_status == 'publish' ) {

					$is_default   = mycred_get_post_meta( $post_id, 'mycred_rank_plus_is_default', true );
					$priority     = mycred_get_post_meta( $post_id, 'mycred_rank_plus_priority', true );
					$requirements = mycred_get_post_meta( $post_id, 'mycred_rank_requirements', true );

					mycred_update_rank_cache(
						$type[0]->term_id,
						array(
							'id'           => $post_id,
							'is_default'   => ! empty( $is_default ),
							'priority'     => $priority,
							'requirements' => $requirements,
						)
					);

				}
				// Delete rank from chache when rank status other then publish
				elseif ( $update ) {

						mycred_remove_rank_from_cache( $post_id );
				}
			}
		}

		public function adjust_rank_cache( $updated_cache, $type, $data, $old_cache ) {

			if ( ! empty( $data['is_default'] ) &&
				! empty( $old_cache['sequence'][ $type ][0] ) &&
				$old_cache['sequence'][ $type ][0] != $data['id']
			) {

				$old_default_rank_id = absint( $old_cache['sequence'][ $type ][0] );

				mycred_update_post_meta( $old_default_rank_id, 'mycred_rank_plus_is_default', false );

				if ( ! empty( $old_cache['ranks'][ end( $old_cache['sequence'][ $type ] ) ]['priority'] ) ) {

					$new_priority = absint( $old_cache['ranks'][ end( $old_cache['sequence'][ $type ] ) ]['priority'] ) + 1;

					if ( empty( $new_priority ) ) {
						$new_priority = 1;
					}

					mycred_update_post_meta( $old_default_rank_id, 'mycred_rank_plus_priority', $new_priority );

					$updated_cache['ranks'][ $old_default_rank_id ]['is_default'] = 0;
					$updated_cache['ranks'][ $old_default_rank_id ]['priority']   = $new_priority;

					$old_index = array_search( $old_default_rank_id, $updated_cache['sequence'][ $type ] );

					if ( false !== $old_index ) {

						unset( $updated_cache['sequence'][ $type ][ $old_index ] );
						$updated_cache['sequence'][ $type ] = array_values( $updated_cache['sequence'][ $type ] );

					}

					$updated_cache['sequence'][ $type ][] = $old_default_rank_id;

				}
			}

			if ( ! empty( $updated_cache['ranks'][ end( $updated_cache['sequence'][ $type ] ) ]['priority'] ) ) {

				update_term_meta( $type, 'max_priority', absint( $updated_cache['ranks'][ end( $updated_cache['sequence'][ $type ] ) ]['priority'] ) );

			}

			return $updated_cache;
		}

		/**
		 * Add Admin Menu Item
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function assign_default_ranks( $user_id ) {

			$ranks_cache = mycred_get_ranks_cache();

			if ( ! empty( $ranks_cache['sequence'] ) && is_array( $ranks_cache['sequence'] ) ) {

				foreach ( $ranks_cache['sequence'] as $rank_type_id => $rank_ids ) {

					if ( empty( $rank_type_id ) || empty( $rank_ids ) || empty( $rank_ids[0] ) ) {
						continue;
					}

					$rank = mycred_rank( $rank_ids[0] );
					$rank->assign( $user_id );

				}
			}
		}

		/**
		 * Delete all ranks and their chache when rank type deleted
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function delete_rank_type( $term, $tt_id, $deleted_term, $object_ids ) {

			$tt_id = absint( $tt_id );

			$ranks_cache = mycred_get_ranks_cache();

			if ( ! empty( $ranks_cache['sequence'][ $tt_id ] ) ) {

				unset( $ranks_cache['sequence'][ $tt_id ] );

			}

			if ( ! empty( $object_ids ) ) {

				foreach ( $object_ids as $rank_id ) {

					$rank_id = absint( $rank_id );

					// Delete rank
					if ( ! empty( $ranks_cache['ranks'][ $rank_id ] ) ) {

						unset( $ranks_cache['ranks'][ $rank_id ] );
						wp_delete_post( $rank_id, true );

					}
				}
			}

			mycred_update_option( 'mycred_rank_cache', $ranks_cache );
		}

		/**
		 * Decrement rank earners count when user deleted
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function delete_user_rank_data( $user_id ) {

			$ranks_cache = mycred_get_ranks_cache();

			if ( ! empty( $ranks_cache['sequence'] ) ) {

				foreach ( $ranks_cache['sequence'] as $rank_type_id => $rank_ids ) {

					$users_rank_id = mycred_get_user_meta( $user_id, 'mycred_current_rank_', $rank_type_id, true );

					if ( ! empty( $users_rank_id ) ) {

						$rank_earners = mycred_get_post_meta( $users_rank_id, 'mycred_rank_earners_count', true );

						if ( ! empty( $rank_earners ) && intval( $rank_earners ) > 0 ) {

							--$rank_earners;
							mycred_update_post_meta( $users_rank_id, 'mycred_rank_earners_count', $rank_earners );

						}
					}
				}
			}
		}

		public function balance_adjustment( $result, $request, $mycred ) {

			// If the result was declined
			if ( $result === false ) {
				return $result;
			}

			extract( $request );

			$ranks_cache = mycred_get_ranks_cache();
			$rank_events = mycred_get_rank_events();

			if ( ! empty( $ranks_cache['sequence'] ) && is_array( $ranks_cache['sequence'] ) ) {

				foreach ( $ranks_cache['sequence'] as $rank_type_id => $rank_ids ) {

					if ( empty( $rank_type_id ) || empty( $rank_ids ) || empty( $rank_ids[0] ) ) {
						continue;
					}

					$users_current_rank_id = mycred_get_users_rank_by_type( $user_id, $rank_type_id );

					if ( empty( $users_current_rank_id ) ) {

						$default_rank = mycred_rank( $rank_ids[0] );
						$default_rank->assign( $user_id );
						$users_current_rank_id = $default_rank->rank_id;

					}

					$current_rank_key = array_search( $users_current_rank_id, $rank_ids );

					if ( ! empty( $rank_ids[ $current_rank_key + 1 ] ) ) {

						$next_rank_id = $rank_ids[ $current_rank_key + 1 ];
						$next_rank    = $ranks_cache['ranks'][ $next_rank_id ];

						$check_requirements = array();

						if ( ! empty( $next_rank['requirements']['requirements'] ) ) {

							foreach ( $next_rank['requirements']['requirements'] as $key => $requirement ) {

								if ( $requirement['required'] == 'optional' ) {

									$check_requirements[] = true;
									continue;

								}

								$requirement_class          = new $rank_events[ $requirement['reference'] ]['class']();
								$current_requirement_status = (bool) $requirement_class->has_met( $user_id, $requirement );
								$check_requirements[]       = $current_requirement_status;

								if ( ! empty( $next_rank['requirements']['is_sequential'] ) && ! $current_requirement_status ) {
									break;
								}
							}
						}

						if ( ! in_array( false, $check_requirements ) ) {

							$rank = mycred_rank( $next_rank_id );
							$rank->assign( $user_id );

						}
					}
				}
			}

			return $result;
		}

	}
endif;