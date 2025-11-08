<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_My_Rank extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve My Rank widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_my_rank';
    }

    /**
     * Get widget title.
     *
     * Retrieve My Rank widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('My Rank', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve My Rank widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the My Rank widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register My Rank widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('My Rank Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Optional ID of a specific user. If you want to show the rank of the user viewing this shortcode, leave this field empty.', 'mycred')
                ]
        );

        $this->add_control(
                'show_title', [
            'label' => __('Show Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Option to show the rank title. Defaults to yes.', 'mycred')
                ]
        );
        $this->add_control(
                'show_logo', [
            'label' => __('Show Logo', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Option to show the rank logo. Defaults to no.', 'mycred')
                ]
        );
        $this->add_control(
                'logo_size', [
            'label' => __('Logo Size', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'post-thumbnail',
            'description' => __('Registered image size or size in pixels e.g. 100x100.', 'mycred')
                ]
        );

        $this->add_control(
                'first', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' =>
            array(
                'logo' => __('Logo then Title', 'mycred'),
                'title' => __('Title then Logo', 'mycred')
            ),
            'default' => 'logo',
            'description' => __('Select what you want to show first. This is ignored if you have selected to only show one detail.', 'mycred')
                ]
        );

        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render My Rank widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }

        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }

        $show_title = $settings['show_title'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_title', $show_title);

        $show_logo = $settings['show_logo'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_logo', $show_logo);

        if (!empty($settings['logo_size'])) {
            $this->add_render_attribute('shortcode', 'logo_size', $settings['logo_size']);
        }

        if (!empty($settings['first'])) {
            $this->add_render_attribute('shortcode', 'first', $settings['first']);
        }


        $shortcode = do_shortcode('[mycred_my_rank ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_My_Ranks extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve My Ranks widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_my_ranks';
    }

    /**
     * Get widget title.
     *
     * Retrieve My Ranks widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('My Ranks', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve My Ranks widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the My Ranks widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register My Ranks widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('My Ranks Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Optional ID of a specific user. If you want to show the rank of the user viewing this shortcode, leave this field empty.', 'mycred')
                ]
        );

        $this->add_control(
                'show_title', [
            'label' => __('Show Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Option to show the rank title. Defaults to yes.', 'mycred')
                ]
        );
        $this->add_control(
                'show_logo', [
            'label' => __('Show Logo', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Option to show the rank logo. Defaults to no.', 'mycred')
                ]
        );
        $this->add_control(
                'logo_size', [
            'label' => __('Logo Size', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'post-thumbnail',
            'description' => __('Registered image size or size in pixels e.g. 100x100.', 'mycred')
                ]
        );

        $this->add_control(
                'first', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' =>
            array(
                'logo' => __('Logo then Title', 'mycred'),
                'title' => __('Title then Logo', 'mycred')
            ),
            'default' => 'logo',
            'description' => __('Select what you want to show first. This is ignored if you have selected to only show one detail.', 'mycred')
                ]
        );



        $this->end_controls_section();
    }

    /**
     * Render My Ranks widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }


        $show_title = $settings['show_title'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_title', $show_title);

        $show_logo = $settings['show_logo'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_logo', $show_logo);

        if (!empty($settings['logo_size'])) {
            $this->add_render_attribute('shortcode', 'logo_size', $settings['logo_size']);
        }

        if (!empty($settings['first'])) {
            $this->add_render_attribute('shortcode', 'first', $settings['first']);
        }

        $shortcode = do_shortcode('[mycred_my_ranks ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Users_Of_Rank extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Total Pts widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_users_of_rank';
    }

    /**
     * Get widget title.
     *
     * Retrieve Users of Rank widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Users of Rank', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Users of Rank widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Users of Rank widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Users of Rank widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Users of Rank Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'rank_id', [
            'label' => __('Rank ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The rank to list users for.', 'mycred')
                ]
        );

        $this->add_control(
                'login', [
            'label' => __('Login Message', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show for logged out users. This shortcode will not return anything if this is left empty.', 'mycred')
                ]
        );

        $this->add_control(
                'number', [
            'label' => __('Number of Users', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '',
            'description' => __('The number of users to return. Use -1 to return all users of this rank.', 'mycred')
                ]
        );

        $this->add_control(
                'wrap', [
            'label' => __('Wrapper Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'div',
            'description' => __('Option to wrap each row in a specific type of HTML element. Defaults to "div" but you can also use "table" to render a table. Can not be empty!', 'mycred')
                ]
        );
        $this->add_control(
                'col', [
            'label' => __('Table Columns', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 1,
            'description' => __('If you are using a table as the wrapper, you can set the number of columns you want to use. Unless you have customized the rendering of this shortcode, this should remain at 1.', 'mycred')
                ]
        );


        $this->add_control(
                'nothing', [
            'label' => __('No Results', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show when the given rank has no users.', 'mycred')
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Row Template', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXTAREA,
            'default' => '<p class="user-row">%user_profile_link% with %balance% %_plural%</p>',
            'description' => __('Template to use for each user.', 'mycred')
                ]
        );

        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Users are sorted according to their balance. Here you can select which order you want to show them. Lowest to highest or highest to lowest.', 'mycred_vc')
                ]
        );

        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Users of Rank widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['rank_id'])) {
            $this->add_render_attribute('shortcode', 'rank_id', $settings['rank_id']);
        }

        if (!empty($settings['login'])) {
            $this->add_render_attribute('shortcode', 'login', $settings['login']);
        }

        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }
        if (!empty($settings['wrap'])) {
            $this->add_render_attribute('shortcode', 'wrap', $settings['wrap']);
        }
        if (!empty($settings['col'])) {
            $this->add_render_attribute('shortcode', 'col', $settings['col']);
        }
        if (!empty($settings['nothing'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['nothing']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }
        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }

        $html = '[mycred_users_of_rank ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_users_of_rank]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Users_Of_All_Ranks extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Users of All Ranks widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_users_of_all_ranks';
    }

    /**
     * Get widget title.
     *
     * Retrieve Users of All Ranks widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Users of All Ranks', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Users of All Ranks widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Users of All Ranks widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Users of All Ranks widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Users of All Ranks Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'show_logo', [
            'label' => __('Show Rank Logo', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Option to show each ranks logo. Defaults to yes.', 'mycred')
                ]
        );

        $this->add_control(
                'logo_size', [
            'label' => __('Logo Size', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The logo size to show. Defaults to "post-thumbnail".', 'mycred')
                ]
        );

        $this->add_control(
                'number', [
            'label' => __('Number of Users', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '',
            'description' => __('The number of users to show per rank. Use -1 to return all users of each rank.', 'mycred')
                ]
        );

        $this->add_control(
                'login', [
            'label' => __('Login Message', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show for logged out users. This shortcode will not return anything if this is left empty.', 'mycred')
                ]
        );

        $this->add_control(
                'wrap', [
            'label' => __('Wrapper Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to wrap each row in a specific type of HTML element. Defaults to "div" but you can also use "table" to render a table.', 'mycred')
                ]
        );

        $this->add_control(
                'nothing', [
            'label' => __('No Results', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show when the given rank has no users.', 'mycred')
                ]
        );

        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show.', 'mycred_vc')
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Rank Template', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXTAREA,
            'default' => '<p class="mycred-rank-user-row">%user_profile_link% with %balance% %_plural%</p>',
            'description' => __('Template to use for each user.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Users of All Ranks widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        $show_logo = $settings['show_logo'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_logo', $show_logo);


        if (!empty($settings['logo_size'])) {
            $this->add_render_attribute('shortcode', 'logo_size', $settings['logo_size']);
        }

        if (!empty($settings['login'])) {
            $this->add_render_attribute('shortcode', 'login', $settings['login']);
        }

        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }

        if (!empty($settings['wrap'])) {
            $this->add_render_attribute('shortcode', 'wrap', $settings['wrap']);
        }

        if (!empty($settings['nothing'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['nothing']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }

        $html = '[mycred_users_of_all_ranks ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_users_of_all_ranks]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_List_Ranks extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve List Ranks widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_list_ranks';
    }

    /**
     * Get widget title.
     *
     * Retrieve List Ranks widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('List Ranks', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve List Ranks widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the List Ranks widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register List Ranks widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('List Ranks Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'wrap', [
            'label' => __('Wrapper', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'div',
            'description' => __('The HTML element to use as the main wrapper around this shortcodes results.', 'mycred')
                ]
        );

        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Rank listing order.', 'mycred')
                ]
        );


        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show.', 'mycred_vc')
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Rank Template', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXTAREA,
            'default' => '<p>%rank% <span class="min">%min%</span> - <span class="max">%max%</span></p>',
            'description' => __('Template to use for each rank.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render List Ranks widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }


        if (!empty($settings['wrap'])) {
            $this->add_render_attribute('shortcode', 'wrap', $settings['wrap']);
        }

        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }

        $html = '[mycred_list_ranks ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_list_ranks]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
