<?php
/**
 * Dashboard helper functions for myCRED Dashboard API
 */
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function mycred_dashboard_resolve_range_bounds( $range, $custom_start = null, $custom_end = null ) {
    $now = current_time( 'timestamp' );

    if ( is_array( $range ) && isset( $range['start'], $range['end'] ) ) {
        $custom_start = $range['start'];
        $custom_end   = $range['end'];
        $range        = 'custom';
    }

    $range_key = is_string( $range ) ? strtolower( $range ) : '';

    switch ( $range_key ) {
        case 'today':
            $start = strtotime( date( 'Y-m-d 00:00:00', $now ) );
            $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
            return array( $start, $end );

        case 'this_week':
        case 'week':
            $weekday = date( 'w', $now );
            $monday  = strtotime( '-' . ( $weekday ? $weekday - 1 : 6 ) . ' days', $now );
            $start   = strtotime( date( 'Y-m-d 00:00:00', $monday ) );
            $end     = strtotime( date( 'Y-m-d 23:59:59', $now ) );
            return array( $start, $end );

        case 'this_month':
        case 'month':
            $start = strtotime( date( 'Y-m-01 00:00:00', $now ) );
            $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
            return array( $start, $end );

        case 'custom':
            $start = $custom_start ? strtotime( $custom_start . ' 00:00:00' ) : null;
            $end   = $custom_end ? strtotime( $custom_end . ' 23:59:59' ) : null;
            if ( $start && $end && $start > $end ) {
                $tmp   = $start;
                $start = $end;
                $end   = $tmp;
            }
            return array( $start, $end );

        default:
            return array( null, null );
    }
}

function mycred_dashboard_get_date_ranges( $range ) {
    $start = $end = null;
    $now = current_time( 'timestamp' );

    if ( is_array( $range ) && isset( $range['start'], $range['end'] ) ) {
        $start = strtotime( $range['start'] . ' 00:00:00' );
        $end   = strtotime( $range['end'] . ' 23:59:59' );
    } else {
        $range_key = is_string( $range ) ? strtolower( $range ) : '';
        switch ( $range_key ) {
            case 'today':
                $start = strtotime( date( 'Y-m-d 00:00:00', $now ) );
                $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
                break;
            case 'yesterday':
                $start = strtotime( date( 'Y-m-d 00:00:00', strtotime( '-1 day' ) ) );
                $end   = strtotime( date( 'Y-m-d 23:59:59', strtotime( '-1 day' ) ) );
                break;
            case 'this_week':
            case 'week':
                $weekday = date( 'w', $now );
                $monday  = strtotime( '-' . ( $weekday ? $weekday - 1 : 6 ) . ' days', $now );
                $start   = strtotime( date( 'Y-m-d 00:00:00', $monday ) );
                $end     = strtotime( date( 'Y-m-d 23:59:59', $now ) );
                break;
            case 'last_week':
                 $start = strtotime( 'monday last week', $now );
                 $end   = strtotime( 'sunday last week', $now ) + 86399; // End of sunday
                 break;
            case 'this_month':
            case 'month':
                $start = strtotime( date( 'Y-m-01 00:00:00', $now ) );
                $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
                break;
            case 'last_month':
                $start = strtotime( 'first day of last month 00:00:00', $now );
                $end   = strtotime( 'last day of last month 23:59:59', $now );
                break;
            default: // Default to this month
                $start = strtotime( date( 'Y-m-01 00:00:00', $now ) );
                $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
                break;
        }
    }

    // Default fallbacks if strtotime fails
    if ( ! $start ) $start = strtotime( date( 'Y-m-01 00:00:00', $now ) );
    if ( ! $end )   $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );

    // Calculate Previous Period
    $period_length = $end - $start + 1;
    $prev_end      = $start - 1;
    $prev_start    = $prev_end - $period_length + 1;

    // Determine Interval for Charts
    $diff = $end - $start;
    $interval = 'day';
    if ( $diff <= 86400 ) $interval = 'hour';
    elseif ( $diff <= 86400 * 7 ) $interval = 'day';
    elseif ( $diff <= 86400 * 31 ) $interval = 'week';
    else $interval = 'month';

    return array(
        'start'      => $start,
        'end'        => $end,
        'prev_start' => $prev_start,
        'prev_end'   => $prev_end,
        'interval'   => $interval
    );
}

function mycred_dashboard_compute_loyalty_metrics( $requested_range, $pt, $log_table ) {
    global $wpdb;
    $mycred = mycred( $pt );
    $now = current_time( 'timestamp' );
    $awarded = 0.0;
    $deducted = 0.0;
    $transactions = 0;
    $total_members = 0;
    $prev_awarded = 0.0;
    $prev_deducted = 0.0;
    $prev_transactions = 0;
    $prev_total_members = 0;

    $ranges = mycred_dashboard_get_date_ranges( $requested_range );
    $start      = $ranges['start'];
    $end        = $ranges['end'];
    $prev_start = $ranges['prev_start'];
    $prev_end   = $ranges['prev_end'];

    if ( $log_table ) {
        $where  = 'ctype = %s AND time >= %s AND time <= %s';
        $params = array( $pt, $start, $end );
        $totals_sql = $wpdb->prepare(
            "SELECT
                SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) AS awarded,
                SUM(CASE WHEN creds < 0 THEN -creds ELSE 0 END) AS deducted,
                COUNT(*) AS transactions
             FROM {$log_table}
             WHERE $where",
            ...$params
        );
        $row = $wpdb->get_row( $totals_sql, ARRAY_A );
        if ( $row ) {
            $awarded      = (float) ( $row['awarded'] ?? 0 );
            $deducted     = (float) ( $row['deducted'] ?? 0 );
            $transactions = (int)   ( $row['transactions'] ?? 0 );
        }

        $members_sql = $wpdb->prepare(
            "SELECT COUNT(DISTINCT user_id) FROM {$log_table} WHERE $where",
            ...$params
        );
        $total_members = (int) $wpdb->get_var( $members_sql );

        $prev_where  = 'ctype = %s AND time >= %s AND time <= %s';
        $prev_params = array( $pt, $prev_start, $prev_end );
        $prev_totals_sql = $wpdb->prepare(
            "SELECT
                SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) AS awarded,
                SUM(CASE WHEN creds < 0 THEN -creds ELSE 0 END) AS deducted,
                COUNT(*) AS transactions
             FROM {$log_table}
             WHERE $prev_where",
            ...$prev_params
        );
        $prev_row = $wpdb->get_row( $prev_totals_sql, ARRAY_A );
        if ( $prev_row ) {
            $prev_awarded      = (float) ( $prev_row['awarded'] ?? 0 );
            $prev_deducted     = (float) ( $prev_row['deducted'] ?? 0 );
            $prev_transactions = (int)   ( $prev_row['transactions'] ?? 0 );
        }

        $prev_members_sql = $wpdb->prepare(
            "SELECT COUNT(DISTINCT user_id) FROM {$log_table} WHERE $prev_where",
            ...$prev_params
        );
        $prev_total_members = (int) $wpdb->get_var( $prev_members_sql );
    }

    $members_percent      = mycred_dashboard_calculate_percentage_change( $prev_total_members, $total_members );
    $awarded_percent      = mycred_dashboard_calculate_percentage_change( $prev_awarded, $awarded );
    $deducted_percent     = mycred_dashboard_calculate_percentage_change( $prev_deducted, $deducted );
    $transactions_percent = mycred_dashboard_calculate_percentage_change( $prev_transactions, $transactions );

    $meta_key = $pt;
    $current_outstanding_sql = $wpdb->prepare( "SELECT SUM(CAST(meta_value AS DECIMAL(20,4))) FROM {$wpdb->usermeta} WHERE meta_key = %s", $meta_key );
    $current_outstanding = (float) $wpdb->get_var( $current_outstanding_sql );

    $net_change_after = 0.0;
    if ( $end < $now ) {
         $after_sql = $wpdb->prepare(
            "SELECT SUM(creds) FROM {$log_table} WHERE ctype = %s AND time > %d",
            $pt, $end
         );
         $net_change_after = (float) $wpdb->get_var( $after_sql );
    }

    $outstanding_at_end = $current_outstanding - $net_change_after;
    $outstanding_formatted = $mycred->format_creds( $outstanding_at_end );

    $net_change_during = $awarded - $deducted;
    $outstanding_at_start = $outstanding_at_end - $net_change_during;
    $outstanding_percent = mycred_dashboard_calculate_percentage_change( $outstanding_at_start, $outstanding_at_end );

    return array(
        'total_members'           => $total_members,
        'total_members_percent'   => $members_percent,
        'points_awarded'          => $awarded,
        'points_awarded_formatted'=> $mycred->format_creds( $awarded ),
        'points_awarded_percent'  => $awarded_percent,
        'points_deducted'         => $deducted,
        'points_deducted_formatted'=> $mycred->format_creds( $deducted ),
        'points_deducted_percent' => $deducted_percent,
        'transactions'            => $transactions,
        'transactions_percent'    => $transactions_percent,
        'outstanding_points'      => $outstanding_at_end,
        'outstanding_points_formatted' => $outstanding_formatted,
        'outstanding_points_percent'   => $outstanding_percent,
    );
}

function mycred_dashboard_compute_woocommerce_metrics( $requested_range, $pt, $log_table ) {
    global $wpdb;

    $now = current_time( 'timestamp' );

    if ( ! class_exists( 'WooCommerce' ) ) {
        return null;
    }

    $ranges = mycred_dashboard_get_date_ranges( $requested_range );
    $start      = $ranges['start'];
    $end        = $ranges['end'];
    $prev_start = $ranges['prev_start'];
    $prev_end   = $ranges['prev_end'];

    // Initialize metrics
    $point_rewarded = 0.0;
    $point_usage = 0.0;
    $referrals = 0;
    $returning_count = 0;
    $prev_point_rewarded = 0.0;
    $prev_point_usage = 0.0;
    $prev_referrals = 0;
    $prev_returning_count = 0;

    $chart_new_vs_returning = null;
    $chart_redemption = null;
    $chart_transactions = null;
    $chart_revenue = null;

    if ( $log_table ) {
        $reward_refs   = array('reward', 'woocommerce_each_order', 'woocommerce_first_order_reward', 'woocommerce_number_of_order_reward', 'woocommerce_order_range');
        $usage_refs    = array('points_to_coupon', 'recurring_payment_woocommerce', 'woocommerce_refund', 'order_cancelation', 'store_sale', 'woocommerce_payment', 'partial_payment_refund', 'partial_payment');
        $referral_refs = array('product_referral_referee', 'product_referral');

        $reward_in   = implode( ',', array_fill( 0, count( $reward_refs ), '%s' ) );
        $usage_in    = implode( ',', array_fill( 0, count( $usage_refs ), '%s' ) );
        $referral_in = implode( ',', array_fill( 0, count( $referral_refs ), '%s' ) );

        // Current period - Points Rewarded
        $point_rewarded = (float) $wpdb->get_var( $wpdb->prepare(
            "SELECT SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $start, $end ), $reward_refs )
        ) );

        // Current period - Points Redeemed (for usage calculation)
        $point_redeemed = (float) $wpdb->get_var( $wpdb->prepare(
            "SELECT SUM(CASE WHEN creds < 0 THEN -creds ELSE 0 END) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($usage_in)",
            array_merge( array( $pt, $start, $end ), $usage_refs )
        ) );
        $point_usage = $point_rewarded > 0 ? ( $point_redeemed / $point_rewarded ) * 100 : 0;

        // Current period - Referrals
        $referrals = (int) $wpdb->get_var( $wpdb->prepare(
            "SELECT COUNT(*) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($referral_in)",
            array_merge( array( $pt, $start, $end ), $referral_refs )
        ));

        // Current period - Returning Customers
        $curr_buyers = array_map( 'intval', (array) $wpdb->get_col( $wpdb->prepare(
            "SELECT DISTINCT user_id FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $start, $end ), $reward_refs )
        ) ) );
        if ( count( $curr_buyers ) > 0 ) {
            $user_in = implode( ',', array_fill( 0, count( $curr_buyers ), '%d' ) );
            $returning_count = (int) $wpdb->get_var( $wpdb->prepare(
                "SELECT COUNT(DISTINCT user_id) FROM {$log_table} 
                 WHERE ctype = %s AND ref IN ($reward_in) AND user_id IN ($user_in)
                 AND user_id IN (
                    SELECT user_id FROM {$log_table} 
                    WHERE ctype = %s AND ref IN ($reward_in)
                    GROUP BY user_id
                    HAVING COUNT(*) > 1
                 )",
                array_merge( array( $pt ), $reward_refs, $curr_buyers, array( $pt ), $reward_refs )
            ) );
        }

        // Previous period - Points Rewarded
        $prev_point_rewarded = (float) $wpdb->get_var( $wpdb->prepare(
            "SELECT SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $prev_start, $prev_end ), $reward_refs )
        ) );

        // Previous period - Points Redeemed (for usage calculation)
        $prev_point_redeemed = (float) $wpdb->get_var( $wpdb->prepare(
            "SELECT SUM(CASE WHEN creds < 0 THEN -creds ELSE 0 END) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($usage_in)",
            array_merge( array( $pt, $prev_start, $prev_end ), $usage_refs )
        ) );
        $prev_point_usage = $prev_point_rewarded > 0 ? ( $prev_point_redeemed / $prev_point_rewarded ) * 100 : 0;

        // Previous period - Referrals
        $prev_referrals = (int) $wpdb->get_var( $wpdb->prepare(
            "SELECT COUNT(*) FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($referral_in)",
            array_merge( array( $pt, $prev_start, $prev_end ), $referral_refs )
        ) );

        $prev_buyers = array_map( 'intval', (array) $wpdb->get_col( $wpdb->prepare(
            "SELECT DISTINCT user_id FROM {$log_table} 
             WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $prev_start, $prev_end ), $reward_refs )
        ) ) );
        if ( count( $prev_buyers ) > 0 ) {
            $user_in = implode( ',', array_fill( 0, count( $prev_buyers ), '%d' ) );
            $prev_returning_count = (int) $wpdb->get_var( $wpdb->prepare(
                "SELECT COUNT(DISTINCT user_id) FROM {$log_table} 
                 WHERE ctype = %s AND ref IN ($reward_in) AND user_id IN ($user_in)
                 AND user_id IN (
                    SELECT user_id FROM {$log_table} 
                    WHERE ctype = %s AND ref IN ($reward_in)
                    GROUP BY user_id
                    HAVING COUNT(*) > 1
                 )",
                array_merge( array( $pt ), $reward_refs, $prev_buyers, array( $pt ), $reward_refs )
            ) );
        }
        
        $total_buyers_count = count( $curr_buyers );
        $new_customers = max( 0, $total_buyers_count - $returning_count );
        
        $chart_new_vs_returning = array(
            array( 'name' => 'New', 'value' => $new_customers ),
            array( 'name' => 'Returning', 'value' => $returning_count )
        );

        $redemption_rate_val = min( 100, max( 0, round( $point_usage ) ) ); 
        $chart_redemption = array(
            array( 'value' => $redemption_rate_val ),
            array( 'value' => 100 - $redemption_rate_val )
        );

        $interval = 'day';
        $diff = $end - $start;
        if ( $diff <= 86400 ) $interval = 'hour';
        elseif ( $diff <= 86400 * 7 ) $interval = 'day';
        elseif ( $diff <= 86400 * 31 ) $interval = 'week';
        else $interval = 'month';

        $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%%Y-%%m-%%d')";
        
        if ( $interval === 'week' ) {
             $group_by = "FLOOR((DAY(FROM_UNIXTIME(time))-1)/7) + 1";
        } elseif ( $interval === 'hour' ) {
             $group_by = "HOUR(FROM_UNIXTIME(time))";
        } elseif ( $interval === 'month' ) {
             $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%%Y-%%m')";
        }

        $chart_transactions = array();
        $keys_map = array();

        if ( $interval === 'hour' ) {
            for ( $i = 0; $i < 24; $i++ ) {
                $hour_timestamp = $start + ( $i * 3600 );
                if ( $hour_timestamp > $now ) break; // Stop if hour is in future
                $key = sprintf('%02d:00', $i);
                $keys_map[] = $i; // Use int index for hours
                $chart_transactions[$i] = array( 'name' => $key, 'value' => 0, 'key' => $i );
            }
        } elseif ( $interval === 'day' ) {
            for ( $i = 0; $i < 7; $i++ ) {
               $t = $start + ($i * 86400);
               if ($t > $end && $requested_range !== 'this_week') break; 
               if ( $t > $now ) break; // Stop if day is in future
               $key = date('Y-m-d', $t);
               $keys_map[] = $key;
               $chart_transactions[$key] = array( 'name' => date('D', $t), 'value' => 0, 'key' => $key );
            }
        } elseif ( $interval === 'week' ) {
            for ( $i = 1; $i <= 5; $i++ ) {
                // Calculate approximate start of the week within the month/period
                // $start is the start of the period (e.g., 1st of month)
                // Week $i starts at $start + ($i-1) weeks
                $week_start_timestamp = $start + ( ($i - 1) * 7 * 86400 );
                if ( $week_start_timestamp > $now ) {
                    break;
                }
                $keys_map[] = $i;
                $chart_transactions[$i] = array( 'name' => "Week $i", 'value' => 0, 'key' => $i );
            }
        } elseif ( $interval === 'month' ) {
            for ( $i = 1; $i <= 12; $i++ ) {
                $m = sprintf('%s-%02d', date('Y', $start), $i);
                // Check if this month is in the future relative to now
                if ( strtotime( "$m-01" ) > $now ) {
                    break;
                }
                $keys_map[] = $m;
                $chart_transactions[$m] = array( 'name' => date('M', strtotime("$m-01")), 'value' => 0, 'key' => $m );
            }
        }

        // Query Transactions
        // We count any entry using 'woocommerce_each_order' as a transaction
        $trans_query = $wpdb->prepare("
            SELECT 
                {$group_by} as bucket,
                COUNT(*) as count
            FROM {$log_table}
            WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)
            GROUP BY bucket
        ", array_merge( array( $pt, $start, $end ), $reward_refs ) );

        $trans_results = $wpdb->get_results( $trans_query, ARRAY_A );

        if ( ! is_array( $trans_results ) ) {
            $trans_results = array();
        }

        foreach ( $trans_results as $row ) {
            $bucket = $row['bucket'];
            if ( isset( $chart_transactions[$bucket] ) ) {
                $chart_transactions[$bucket]['value'] = (int) $row['count'];
            } else {
                 // Fallback
                 $chart_transactions[$bucket] = array( 'name' => $bucket, 'value' => (int) $row['count'] );
            }
        }

        // 4. Revenue Impact
        // Logic: 
        // "With Rewards": Sum of order totals where user key exists in log for that period OR order ID is in log references (more accurate).
        // "Without Rewards": Total Revenue - With Rewards.
        
        // We need to query Orders by Date.
        // Assuming Legacy Orders (wp_posts + wp_postmeta) for widest compatibility, 
        // checking order_date.
        // Note: For High-Performance Order Storage (HPOS), we'd need to query wp_wc_orders.
        // We will implement a check.

        $revenue_by_date = array();

        // Check for HPOS table
        $hpos_table = $wpdb->prefix . 'wc_orders';
        $use_hpos = $wpdb->get_var("SHOW TABLES LIKE '$hpos_table'") === $hpos_table;

        // Create separate GROUP BY clauses for HPOS and legacy tables
        $group_by_hpos = $group_by; // Default to log-based grouping
        $group_by_legacy = $group_by;
        
        // For HPOS, we need to use date_created_gmt instead of time
        if ( $interval === 'week' ) {
             $group_by_hpos = "FLOOR((DAY(date_created_gmt)-1)/7) + 1";
             $group_by_legacy = "FLOOR((DAY(p.post_date)-1)/7) + 1";
        } elseif ( $interval === 'hour' ) {
             $group_by_hpos = "HOUR(date_created_gmt)";
             $group_by_legacy = "HOUR(p.post_date)";
        } elseif ( $interval === 'month' ) {
             $group_by_hpos = "DATE_FORMAT(date_created_gmt, '%%Y-%%m')";
             $group_by_legacy = "DATE_FORMAT(p.post_date, '%%Y-%%m')";
        } else { // day
             $group_by_hpos = "DATE_FORMAT(date_created_gmt, '%%Y-%%m-%%d')";
             $group_by_legacy = "DATE_FORMAT(p.post_date, '%%Y-%%m-%%d')";
        }

        if ($use_hpos) {
             // Query HPOS
             $rev_query = $wpdb->prepare("
                SELECT 
                    {$group_by_hpos} as bucket,
                    SUM(total_amount) as total_sales
                FROM {$hpos_table}
                WHERE date_created_gmt >= FROM_UNIXTIME(%d) 
                  AND date_created_gmt <= FROM_UNIXTIME(%d)
                  AND status IN ('wc-completed', 'wc-processing')
                GROUP BY bucket
            ", $start, $end);
        } else {
             // Query Legacy wp_posts
             $rev_query = $wpdb->prepare("
                SELECT 
                    {$group_by_legacy} as bucket,
                    SUM(pm.meta_value) as total_sales
                FROM {$wpdb->posts} p
                JOIN {$wpdb->postmeta} pm ON p.ID = pm.post_id
                WHERE p.post_type = 'shop_order'
                  AND p.post_status IN ('wc-completed', 'wc-processing')
                  AND p.post_date >= FROM_UNIXTIME(%d)
                  AND p.post_date <= FROM_UNIXTIME(%d)
                  AND pm.meta_key = '_order_total'
                GROUP BY bucket
             ", $start, $end);
        }

        $rev_results = $wpdb->get_results( $rev_query, ARRAY_A );

        if ( ! is_array( $rev_results ) ) {
            $rev_results = array();
        }
        
        // Map total revenue to buckets
        foreach ($rev_results as $row) {
            $revenue_by_date[$row['bucket']] = (float)$row['total_sales'];
        }

        // Now we need "With Rewards". This is tricky. 
        // Simplified approach: If a 'woocommerce_each_order' log exists for an order, it's "With Rewards".
        // But logs don't store Order Date, they store Log Time (usually close).
        // We'll use the Log Time for the "With Rewards" bucket.
        // Sum the ORDER TOTAL for logs ref='woocommerce_each_order'.
        // Ref ID is usually Order ID.
        
        if ($use_hpos) {
             $rewards_rev_query = $wpdb->prepare("
                SELECT 
                    {$group_by} as bucket,
                    SUM(o.total_amount) as reward_sales
                FROM {$log_table} l
                JOIN {$hpos_table} o ON l.ref_id = o.id
                WHERE l.ref IN ($reward_in)
                  AND l.ctype = %s 
                  AND l.time >= %d 
                  AND l.time <= %d
                GROUP BY bucket
             ", array_merge( $reward_refs, array( $pt, $start, $end ) ) );
        } else {
             $rewards_rev_query = $wpdb->prepare("
                SELECT 
                    {$group_by} as bucket,
                    SUM(pm.meta_value) as reward_sales
                FROM {$log_table} l
                JOIN {$wpdb->postmeta} pm ON l.ref_id = pm.post_id
                WHERE l.ref IN ($reward_in)
                  AND l.ctype = %s 
                  AND l.time >= %d 
                  AND l.time <= %d
                  AND pm.meta_key = '_order_total'
                GROUP BY bucket
             ", array_merge( $reward_refs, array( $pt, $start, $end ) ) );
        }

        $rewards_rev_results = $wpdb->get_results( $rewards_rev_query, ARRAY_A );
        
        if ( ! is_array( $rewards_rev_results ) ) {
            $rewards_rev_results = array();
        }

        $rewards_by_date = array();
         foreach ($rewards_rev_results as $row) {
            $rewards_by_date[$row['bucket']] = (float)$row['reward_sales'];
        }

        // Populate Revenue Chart
        $chart_revenue = array(); 
        $total_revenue_period = 0.0;
        $reward_sales_period = 0.0;
        $total_orders_period = 0;
        $reward_orders_period = 0;

        foreach($chart_transactions as $key => $v) {
            $total_sales = isset($revenue_by_date[$key]) ? $revenue_by_date[$key] : 0;
            $reward_sales = isset($rewards_by_date[$key]) ? $rewards_by_date[$key] : 0;
            $without_rewards = max(0, $total_sales - $reward_sales);
            
            $total_revenue_period += $total_sales;
            $reward_sales_period += $reward_sales;
            
            $chart_revenue[] = array(
                'name'    => $v['name'],
                'with'    => $reward_sales,
                'without' => $without_rewards
            );
        }

        // Count total orders in period for AOV
        if ($use_hpos) {
            $total_orders_period = (int) $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM {$hpos_table} WHERE date_created_gmt >= FROM_UNIXTIME(%d) AND date_created_gmt <= FROM_UNIXTIME(%d) AND status IN ('wc-completed', 'wc-processing')",
                $start, $end
            ));
        } else {
            $total_orders_period = (int) $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM {$wpdb->posts} WHERE post_type = 'shop_order' AND post_status IN ('wc-completed', 'wc-processing') AND post_date >= FROM_UNIXTIME(%d) AND post_date <= FROM_UNIXTIME(%d)",
                $start, $end
            ));
        }
        
        $reward_orders_period = (int) $wpdb->get_var($wpdb->prepare(
            "SELECT COUNT(DISTINCT ref_id) FROM {$log_table} WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $start, $end ), $reward_refs )
        ));

        // AOV Calculations
        $aov_with = $reward_orders_period > 0 ? $reward_sales_period / $reward_orders_period : 0;
        $non_reward_orders = max(0, $total_orders_period - $reward_orders_period);
        $non_reward_sales = max(0, $total_revenue_period - $reward_sales_period);
        $aov_without = $non_reward_orders > 0 ? $non_reward_sales / $non_reward_orders : 0;
        
        $aov_lift = $aov_without > 0 ? (($aov_with - $aov_without) / $aov_without) * 100 : 0;
        
        // --- Previous Period AOV Lift Calculation ---
        $prev_reward_sales = 0.0;
        $prev_total_orders = 0;
        $prev_reward_orders = 0;

        // 1. Previous Reward Sales
        if ($use_hpos) {
             $prev_rewards_rev_query = $wpdb->prepare("
                SELECT SUM(o.total_amount) 
                FROM {$log_table} l
                JOIN {$hpos_table} o ON l.ref_id = o.id
                WHERE l.ref IN ($reward_in)
                  AND l.ctype = %s 
                  AND l.time >= %d 
                  AND l.time <= %d
             ", array_merge( $reward_refs, array( $pt, $prev_start, $prev_end ) ) );
        } else {
             $prev_rewards_rev_query = $wpdb->prepare("
                SELECT SUM(pm.meta_value) 
                FROM {$log_table} l
                JOIN {$wpdb->postmeta} pm ON l.ref_id = pm.post_id
                WHERE l.ref IN ($reward_in)
                  AND l.ctype = %s 
                  AND l.time >= %d 
                  AND l.time <= %d
                  AND pm.meta_key = '_order_total'
             ", array_merge( $reward_refs, array( $pt, $prev_start, $prev_end ) ) );
        }
        $prev_reward_sales = (float) $wpdb->get_var( $prev_rewards_rev_query );

        // 2. Previous Total Orders
        if ($use_hpos) {
            $prev_total_orders = (int) $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM {$hpos_table} WHERE date_created_gmt >= FROM_UNIXTIME(%d) AND date_created_gmt <= FROM_UNIXTIME(%d) AND status IN ('wc-completed', 'wc-processing')",
                $prev_start, $prev_end
            ));
        } else {
            $prev_total_orders = (int) $wpdb->get_var($wpdb->prepare(
                "SELECT COUNT(*) FROM {$wpdb->posts} WHERE post_type = 'shop_order' AND post_status IN ('wc-completed', 'wc-processing') AND post_date >= FROM_UNIXTIME(%d) AND post_date <= FROM_UNIXTIME(%d)",
                $prev_start, $prev_end
            ));
        }

        // 3. Previous Reward Orders
        $prev_reward_orders = (int) $wpdb->get_var($wpdb->prepare(
            "SELECT COUNT(DISTINCT ref_id) FROM {$log_table} WHERE ctype = %s AND time >= %d AND time <= %d AND ref IN ($reward_in)",
            array_merge( array( $pt, $prev_start, $prev_end ), $reward_refs )
        ));

        $chart_transactions = array_values( $chart_transactions );

        if ($use_hpos) {
            $prev_revenue = (float) $wpdb->get_var($wpdb->prepare(
                "SELECT SUM(total_amount) FROM {$hpos_table} WHERE date_created_gmt >= FROM_UNIXTIME(%d) AND date_created_gmt <= FROM_UNIXTIME(%d) AND status IN ('wc-completed', 'wc-processing')",
                $prev_start, $prev_end
            ));
        } else {
            $prev_revenue = (float) $wpdb->get_var($wpdb->prepare(
                "SELECT SUM(pm.meta_value) FROM {$wpdb->posts} p JOIN {$wpdb->postmeta} pm ON p.ID = pm.post_id WHERE p.post_type = 'shop_order' AND p.post_status IN ('wc-completed', 'wc-processing') AND p.post_date >= FROM_UNIXTIME(%d) AND p.post_date <= FROM_UNIXTIME(%d) AND pm.meta_key = '_order_total'",
                $prev_start, $prev_end
            ));
        }

        $prev_aov_with = $prev_reward_orders > 0 ? $prev_reward_sales / $prev_reward_orders : 0;
        $prev_non_reward_orders = max(0, $prev_total_orders - $prev_reward_orders);
        $prev_non_reward_sales = max(0, $prev_revenue - $prev_reward_sales);
        $prev_aov_without = $prev_non_reward_orders > 0 ? $prev_non_reward_sales / $prev_non_reward_orders : 0;
        $prev_aov_lift = $prev_aov_without > 0 ? (($prev_aov_with - $prev_aov_without) / $prev_aov_without) * 100 : 0;


    $rewarded_percent = mycred_dashboard_calculate_percentage_change( $prev_point_rewarded, $point_rewarded );
    $usage_percent    = mycred_dashboard_calculate_percentage_change( $prev_point_usage, $point_usage );
    $referral_percent = mycred_dashboard_calculate_percentage_change( $prev_referrals, $referrals );
    $returning_percent = mycred_dashboard_calculate_percentage_change( $prev_returning_count, $returning_count );
    $revenue_percent = mycred_dashboard_calculate_percentage_change( $prev_revenue, $total_revenue_period );
    $aov_lift_percent = mycred_dashboard_calculate_percentage_change( $prev_aov_lift, $aov_lift );

    $mycred = mycred( $pt );
    $currency_symbol = html_entity_decode( get_woocommerce_currency_symbol(), ENT_QUOTES, 'UTF-8' );

    $point_usage_formatted = ( fmod( $point_usage, 1 ) !== 0.0 ) ? number_format( $point_usage, 2 ) : number_format( $point_usage, 0 );
    $aov_lift_formatted = ( fmod( $aov_lift, 1 ) !== 0.0 ) ? number_format( $aov_lift, 1 ) . '%' : number_format( $aov_lift, 0 ) . '%';

    return array(
        'point_rewarded'              => $point_rewarded,
        'point_rewarded_formatted'    => $mycred->format_creds( $point_rewarded ),
        'point_rewarded_percent'      => $rewarded_percent,
        'point_redeemed'              => $point_redeemed,
        'point_redeemed_formatted'    => $mycred->format_creds( $point_redeemed ),
        'point_redeemed_percent'      => $usage_percent,
        'revenue'                     => $currency_symbol . number_format($total_revenue_period, 0),
        'currency_symbol'             => $currency_symbol,
        'revenue_percent'             => $revenue_percent,
        'aov_lift'                    => $aov_lift_formatted,
        'aov_lift_percent'            => $aov_lift_percent,
        'referrals'                   => $referrals,
        'referrals_percent'           => $referral_percent,
        'returning_customers'         => $returning_count,
        'returning_customers_percent' => $returning_percent,
        'charts' => array(
            'new_vs_returning' => $chart_new_vs_returning,
            'redemption_rate'  => $chart_redemption,
            'transactions'     => $chart_transactions,
            'revenue_impact'   => $chart_revenue,
        ),
    );
}
}

function mycred_dashboard_pointsDistribution( $range, $point_type, $log_table ) {
    global $wpdb;

    $ranges = mycred_dashboard_get_date_ranges( $range );
    $start    = $ranges['start'];
    $end      = $ranges['end'];
    $interval = $ranges['interval'];

    $where_clause = $wpdb->prepare( "WHERE time BETWEEN %d AND %d", $start, $end );
    if ( ! empty( $point_type ) ) {
        $where_clause .= $wpdb->prepare( " AND ctype = %s", $point_type );
    }

    // Determine SQL grouping
    $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%Y-%m-%d')";
    if ( $interval === 'week' ) {
         $group_by = "FLOOR((DAY(FROM_UNIXTIME(time))-1)/7) + 1";
    } elseif ( $interval === 'hour' ) {
         $group_by = "HOUR(FROM_UNIXTIME(time))";
    } elseif ( $interval === 'month' ) {
         $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%Y-%m')";
    }

    $query = "
        SELECT 
            {$group_by} as bucket,
            ref,
            SUM(ABS(creds)) as points
        FROM {$log_table}
        {$where_clause}
        AND ref != ''
        GROUP BY bucket, ref
        ORDER BY bucket ASC
    ";

    $results = $wpdb->get_results( $query, ARRAY_A );

    // Prepare buckets
    $chart_buckets = array();
    
    // Fill empty buckets based on interval to ensure continuous chart
    if ( $interval === 'hour' ) {
        $now = current_time( 'timestamp' );
        for ( $i = 0; $i < 24; $i++ ) {
            $hour_timestamp = $start + ( $i * 3600 );
            if ( $hour_timestamp > $now ) break;
            $chart_buckets[$i] = array( 'name' => sprintf('%02d:00', $i), 'Total' => 0 );
        }
    } elseif ( $interval === 'day' ) {
        // Fill 7 days starting from Monday
        $now = current_time( 'timestamp' );
        for ( $i = 0; $i < 7; $i++ ) {
           $t = $start + ($i * 86400);
           if ($t > $end && $range !== 'this_week') break; 
           if ( $t > $now ) break;
           $chart_buckets[date('Y-m-d', $t)] = array( 'name' => date('D', $t), 'Total' => 0 );
        }
    } elseif ( $interval === 'week' ) {
        $now = current_time( 'timestamp' );
        for ( $i = 1; $i <= 5; $i++ ) {
            $week_start_timestamp = $start + ( ($i - 1) * 7 * 86400 );
            if ( $week_start_timestamp > $now ) break;
            $chart_buckets[$i] = array( 'name' => "Week $i", 'Total' => 0 );
        }
    } elseif ( $interval === 'month' ) {
        $now = current_time( 'timestamp' );
        for ( $i = 1; $i <= 12; $i++ ) {
            $m = sprintf('%s-%02d', date('Y', $start), $i);
            if ( strtotime( "$m-01" ) > $now ) break;
            $chart_buckets[$m] = array( 'name' => date('M', strtotime("$m-01")), 'Total' => 0 );
        }
    }

    foreach ( $results as $row ) {
        $bucket = $row['bucket'];
        if ( ! isset( $chart_buckets[$bucket] ) ) {
            // Fallback for custom ranges that don't fit pre-filled logic
            if (!isset($chart_buckets[$bucket])) {
                $chart_buckets[$bucket] = array( 'name' => $bucket, 'Total' => 0 );
            }
        }
        
        $readable_ref = ucwords( str_replace( array( '_', '-' ), ' ', $row['ref'] ) );
        // Whitelist common refs or make it dynamic? Dynamic is better based on previous turns.
        // But for stacked bar, we need consistent keys.
        
        $points = (float) $row['points'];
        $chart_buckets[$bucket][$readable_ref] = $points;
        $chart_buckets[$bucket]['Total'] += $points;
    }

    return array_values( $chart_buckets );
}

function mycred_dashboard_recent_activities( $range, $point_type, $log_table ) {
    global $wpdb;

    $ranges = mycred_dashboard_get_date_ranges( $range );
    $start = $ranges['start'];
    $end   = $ranges['end'];

    $where_clause = "WHERE 1=1";
    if ( ! empty( $start ) && ! empty( $end ) ) {
        $where_clause .= $wpdb->prepare( " AND time BETWEEN %d AND %d", $start, $end );
    }
    
    if ( ! empty( $point_type ) ) {
        $where_clause .= $wpdb->prepare( " AND ctype = %s", $point_type );
    }

    $query = "
        SELECT 
            id,
            user_id,
            creds,
            ctype,
            time,
            entry,
            ref,
            ref_id,
            data
        FROM {$log_table}
        {$where_clause}
        ORDER BY time DESC
        LIMIT 20
    ";

    $results = $wpdb->get_results( $query, ARRAY_A );

    if ( empty( $results ) ) {
        return array();
    }

    // Format the data for recent activities
    $activities = array();
    
    foreach ( $results as $row ) {
        $user = get_user_by( 'id', $row['user_id'] );
        
        if ( ! $user ) {
            continue;
        }

        // Format the reference name to be more readable
        $action = ucwords( str_replace( array( '_', '-' ), ' ', $row['ref'] ) );
        
        // Determine if it's a credit or debit
        $creds = floatval( $row['creds'] );
        $type = $creds >= 0 ? 'credit' : 'debit';
        
        // Process template tags in log entry
        $description = $row['entry'];
        if ( function_exists( 'mycred' ) ) {
            $mycred = mycred($point_type);
            if ( $mycred && method_exists( $mycred, 'parse_template_tags' ) ) {
                // Create a standard object to mimic what parse_template_tags expects
                $log_entry = new stdClass();
                $log_entry->ref = $row['ref'];
                $log_entry->ref_id = $row['ref_id'];
                $log_entry->data = maybe_unserialize( $row['data'] ); // Ensure data is unserialized/prepared
                
                $description = $mycred->parse_template_tags( $row['entry'], $log_entry );
            } elseif ( $mycred && method_exists( $mycred, 'template_tags_general' ) ) {
                 $description = $mycred->template_tags_general( $row['entry'] );
            }
        }
       
        
            $activities[] = array(
                'id'               => (int) $row['id'],
                'user_id'          => (int) $row['user_id'],
                'user_name'        => $user->display_name ?: $user->user_login,
                'points'           => abs( $creds ),
                'points_formatted' => $mycred->format_creds( abs( $creds ) ),
                'type'             => $type,
                'action'           => $action,
                'description'      => $description,
                'time'             => (int) $row['time'],
                'time_ago'         => human_time_diff( $row['time'], current_time( 'timestamp' ) ) . ' ago',
                'ref'              => $row['ref'],
                'ref_id'           => (int) $row['ref_id']
            );
    }

    return $activities;
}

function mycred_dashboard_user_summary( $user_id, $point_type, $log_table, $start = null, $end = null ) {
    global $wpdb;

    $earned = 0.0111;
    $spent  = 0.0;

    
    if ( $log_table ) {
        $clauses = array( 'ctype = %s', 'user_id = %d' );
        $params  = array( $point_type, $user_id );

        if ( null !== $start ) {
            $clauses[] = 'time >= %d';
            $params[]  = $start;
        }

        if ( null !== $end ) {
            $clauses[] = 'time <= %d';
            $params[]  = $end;
        }

        $where = implode( ' AND ', $clauses );

        $sql = $wpdb->prepare(
            "SELECT
                SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) AS earned,
                SUM(CASE WHEN creds < 0 THEN -creds ELSE 0 END) AS spent
             FROM {$log_table}
             WHERE {$where}",
            ...$params
        );

        $row = $wpdb->get_row( $sql, ARRAY_A );
        if ( $row ) {
            $earned = isset( $row['earned'] ) ? (float) $row['earned'] : 0.0;
            $spent  = isset( $row['spent'] ) ? (float) $row['spent'] : 0.0;
        }
    }

    $balance = 0.0;
    if ( function_exists( 'mycred_get_users_cred' ) ) {
        $balance = mycred_get_users_cred( $user_id, $point_type );
    } elseif ( function_exists( 'mycred_get_users_balance' ) ) {
        $balance = mycred_get_users_balance( $user_id, $point_type );
    }

    $mycred = mycred( $point_type );

    return array(
        'earned'            => $earned,
        'earned_formatted'  => $mycred->format_creds( $earned ),
        'spent'             => $spent,
        'spent_formatted'   => $mycred->format_creds( $spent ),
        'balance'           => (float) $balance,
        'balance_formatted' => $mycred->format_creds( $balance ),
    );
}

function mycred_dashboard_user_distribution( $user_id, $point_type, $log_table, $start = null, $end = null, $limit = 12 ) {
    global $wpdb;

    if ( ! $log_table ) {
        return array();
    }

    // Build range array for mycred_dashboard_get_date_ranges
    // If start/end are provided, create a custom range
    $range = 'this_month'; // default
    if ( $start && $end ) {
        $range = array(
            'start' => date('Y-m-d', $start),
            'end' => date('Y-m-d', $end)
        );
    }

    $ranges = mycred_dashboard_get_date_ranges( $range );
    $start    = $ranges['start'];
    $end      = $ranges['end'];
    $interval = $ranges['interval'];

    $where_clause = $wpdb->prepare( "WHERE time BETWEEN %d AND %d", $start, $end );
    if ( ! empty( $point_type ) ) {
        $where_clause .= $wpdb->prepare( " AND ctype = %s", $point_type );
    }
    // Add user_id filter
    $where_clause .= $wpdb->prepare( " AND user_id = %d", $user_id );

    // Determine SQL grouping (same logic as main dashboard)
    $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%Y-%m-%d')";
    if ( $interval === 'week' ) {
         $group_by = "FLOOR((DAY(FROM_UNIXTIME(time))-1)/7) + 1";
    } elseif ( $interval === 'hour' ) {
         $group_by = "HOUR(FROM_UNIXTIME(time))";
    } elseif ( $interval === 'month' ) {
         $group_by = "DATE_FORMAT(FROM_UNIXTIME(time), '%Y-%m')";
    }

    $query = "
        SELECT 
            {$group_by} as bucket,
            ref,
            SUM(ABS(creds)) as points
        FROM {$log_table}
        {$where_clause}
        AND ref != ''
        GROUP BY bucket, ref
        ORDER BY bucket ASC
    ";

    $results = $wpdb->get_results( $query, ARRAY_A );

    // Prepare buckets (same logic as main dashboard)
    $chart_buckets = array();
    
    // Fill empty buckets based on interval to ensure continuous chart
    $now = current_time( 'timestamp' );

    if ( $interval === 'hour' ) {
        for ( $i = 0; $i < 24; $i++ ) {
            $hour_timestamp = $start + ( $i * 3600 );
            if ( $hour_timestamp > $now ) break;
            $chart_buckets[$i] = array( 'name' => sprintf('%02d:00', $i), 'Total' => 0 );
        }
    } elseif ( $interval === 'day' ) {
        // Fill days in range
        for ( $i = 0; $i < 7; $i++ ) {
           $t = $start + ($i * 86400);
           if ($t > $end && $range !== 'this_week') break; 
           if ( $t > $now ) break;
           $chart_buckets[date('Y-m-d', $t)] = array( 'name' => date('D', $t), 'Total' => 0 );
        }
    } elseif ( $interval === 'week' ) {
        for ( $i = 1; $i <= 5; $i++ ) {
            $week_start_timestamp = $start + ( ($i - 1) * 7 * 86400 );
            if ( $week_start_timestamp > $now ) break;
            $chart_buckets[$i] = array( 'name' => "Week $i", 'Total' => 0 );
        }
    } elseif ( $interval === 'month' ) {
        for ( $i = 1; $i <= 12; $i++ ) {
            $m = sprintf('%s-%02d', date('Y', $start), $i);
            if ( strtotime( "$m-01" ) > $now ) break;
            $chart_buckets[$m] = array( 'name' => date('M', strtotime("$m-01")), 'Total' => 0 );
        }
    }

    foreach ( $results as $row ) {
        $bucket = $row['bucket'];
        if ( ! isset( $chart_buckets[$bucket] ) ) {
            // Fallback for custom ranges that don't fit pre-filled logic
            if (!isset($chart_buckets[$bucket])) {
                $chart_buckets[$bucket] = array( 'name' => $bucket, 'Total' => 0 );
            }
        }
        
        $readable_ref = ucwords( str_replace( array( '_', '-' ), ' ', $row['ref'] ) );
        
        $points = (float) $row['points'];
        $chart_buckets[$bucket][$readable_ref] = $points;
        $chart_buckets[$bucket]['Total'] += $points;
    }

    return array_values( $chart_buckets );
}

function mycred_dashboard_user_rankings( $user_id, $point_type, $limit = 10, $log_table = null, $start = null, $end = null ) {
    global $wpdb;

    $limit     = absint( $limit );
    $meta_key  = $point_type ?: 'mycred_default';
    $mycred    = mycred( $point_type );
    $members   = array();
    $rank      = 1;
    $seen_ids  = array();
    $found     = false;

    // Use Log Table if provided (Strict Date Filtering)
    if ( $log_table && null !== $start && null !== $end ) {
        $query = $wpdb->prepare(
            "SELECT u.ID, u.display_name, u.user_login, u.user_nicename,
                    SUM(CASE WHEN l.creds > 0 THEN l.creds ELSE 0 END) AS earned_points
             FROM {$wpdb->users} u
             INNER JOIN {$log_table} l ON u.ID = l.user_id
             WHERE l.ctype = %s AND l.time BETWEEN %d AND %d
             GROUP BY u.ID
             HAVING earned_points > 0
             ORDER BY earned_points DESC
             LIMIT %d",
            $point_type,
            $start,
            $end,
            $limit
        );

        $results = $wpdb->get_results( $query, ARRAY_A );

        foreach ( (array) $results as $row ) {
            $member_id = (int) $row['ID'];
            $earned    = (float) $row['earned_points'];
            $is_target = ( $member_id === (int) $user_id );
            $seen_ids[] = $member_id;
            
            if ( $is_target ) {
                $found = true;
            }

            $members[] = array(
                'rank'             => $rank++,
                'user_id'          => $member_id,
                'user_name'        => $row['display_name'] ?: $row['user_login'],
                'user_handle'      => '@' . $row['user_nicename'],
                'points'           => $earned,
                'points_formatted' => $mycred->format_creds( $earned ),
                'is_target'        => $is_target,
            );
        }

        if ( ! $found ) {
            $target_earned = $wpdb->get_var( $wpdb->prepare(
                "SELECT SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END)
                 FROM {$log_table}
                 WHERE user_id = %d AND ctype = %s AND time BETWEEN %d AND %d",
                $user_id,
                $point_type,
                $start,
                $end
            ) );

            if ( $target_earned && (float) $target_earned > 0 ) {
                $target_earned = (float) $target_earned;
                $rank_position = $wpdb->get_var( $wpdb->prepare(
                    "SELECT COUNT(DISTINCT user_id) + 1
                     FROM {$log_table}
                     WHERE ctype = %s AND time BETWEEN %d AND %d
                     GROUP BY user_id
                     HAVING SUM(CASE WHEN creds > 0 THEN creds ELSE 0 END) > %f",
                    $point_type,
                    $start,
                    $end,
                    $target_earned
                ) );

                $rank_position = $rank_position ? (int) $rank_position : 1;
                $user = get_user_by( 'id', $user_id );
                if ( $user ) {
                    $members[] = array(
                        'rank'             => $rank_position,
                        'user_id'          => (int) $user_id,
                        'user_name'        => $user->display_name ?: $user->user_login,
                        'user_handle'      => '@' . $user->user_nicename,
                        'points'           => $target_earned,
                        'points_formatted' => $mycred->format_creds( $target_earned ),
                        'is_target'        => true,
                    );
                }
            }
        }
    } 
    // Fallback to usermeta (All-time context or if no logs provided)
    else {
        $sql = $wpdb->prepare(
            "SELECT u.ID, u.display_name, u.user_login, u.user_nicename,
                    CAST(um.meta_value AS DECIMAL(20,4)) AS balance
             FROM {$wpdb->usermeta} um
             INNER JOIN {$wpdb->users} u ON u.ID = um.user_id
             WHERE um.meta_key = %s
             ORDER BY balance DESC
             LIMIT %d",
            $meta_key,
            $limit
        );

        $results = $wpdb->get_results( $sql, ARRAY_A );

        foreach ( (array) $results as $row ) {
            $balance = isset( $row['balance'] ) ? (float) $row['balance'] : 0.0;
            if ( $balance <= 0 ) {
                continue;
            }

            $member_id  = (int) $row['ID'];
            $is_target  = ( $member_id === (int) $user_id );
            $seen_ids[] = $member_id;
            if ( $is_target ) {
                $found = true;
            }

            $members[] = array(
                'rank'             => $rank++,
                'user_id'          => $member_id,
                'user_name'        => $row['display_name'] ?: $row['user_login'],
                'user_handle'      => '@' . $row['user_nicename'],
                'points'           => (float) $balance,
                'points_formatted' => $mycred->format_creds( $balance ),
                'is_target'        => $is_target,
            );
        }

        if ( ! $found ) {
            $target_balance = $wpdb->get_var( $wpdb->prepare(
                "SELECT CAST(meta_value AS DECIMAL(20,4))
                 FROM {$wpdb->usermeta}
                 WHERE user_id = %d AND meta_key = %s
                 LIMIT 1",
                $user_id,
                $meta_key
            ) );

            if ( null !== $target_balance && (float) $target_balance > 0 ) {
                $target_balance = (float) $target_balance;
                $rank_position = $wpdb->get_var( $wpdb->prepare(
                    "SELECT COUNT(*) + 1
                     FROM {$wpdb->usermeta}
                     WHERE meta_key = %s AND CAST(meta_value AS DECIMAL(20,4)) > %f",
                    $meta_key,
                    $target_balance
                ) );

                $rank_position = $rank_position ? (int) $rank_position : 1;
                $user = get_user_by( 'id', $user_id );
                if ( $user ) {
                    $members[] = array(
                        'rank'             => $rank_position,
                        'user_id'          => (int) $user_id,
                        'user_name'        => $user->display_name ?: $user->user_login,
                        'user_handle'      => '@' . $user->user_nicename,
                        'points'           => (float) $target_balance,
                        'points_formatted' => $mycred->format_creds( $target_balance ),
                        'is_target'        => true,
                    );
                }
            }
        }
    }

    return $members;
}

function mycred_dashboard_top_members( $range, $point_type, $log_table ) {
    global $wpdb;

    $now = current_time( 'timestamp' );
    $start = $end = null;
    if ( is_array( $range ) && isset( $range['start'], $range['end'] ) ) {
        $start = strtotime( $range['start'] . ' 00:00:00' );
        $end   = strtotime( $range['end'] . ' 23:59:59' );
    } elseif ( $range === 'today' ) {
        $start = strtotime( date( 'Y-m-d 00:00:00', $now ) );
        $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
    } elseif ( $range === 'this_week' ) {
        $weekday = date( 'w', $now );
        $monday  = strtotime( '-' . ( $weekday ? $weekday - 1 : 6 ) . ' days', $now );
        $start   = strtotime( date( 'Y-m-d 00:00:00', $monday ) );
        $end     = strtotime( date( 'Y-m-d 23:59:59', $now ) );
    } else {
        $start = strtotime( date( 'Y-m-01 00:00:00', $now ) );
        $end   = strtotime( date( 'Y-m-d 23:59:59', $now ) );
    }

    $members = array();
    $rank    = 1;


    if ( $log_table ) {
        $query = $wpdb->prepare(
            "SELECT u.ID, u.display_name, u.user_login, u.user_nicename,
                    SUM(CASE WHEN l.creds > 0 THEN l.creds ELSE 0 END) AS earned_points
             FROM {$wpdb->users} u
             INNER JOIN {$log_table} l ON u.ID = l.user_id
             WHERE l.ctype = %s AND l.time BETWEEN %d AND %d
             GROUP BY u.ID
             HAVING earned_points > 0
             ORDER BY earned_points DESC
             LIMIT 10",
            $point_type,
            $start,
            $end
        );

        $results = $wpdb->get_results( $query, ARRAY_A );

        foreach ( (array) $results as $row ) {
            $user_id = (int) $row['ID'];
            $earned  = (float) $row['earned_points'];

            if ( $earned <= 0 ) {
                continue;
            }

            $mycred = mycred( $point_type );

            $members[] = array(
                'rank'             => $rank++,
                'user_id'          => $user_id,
                'user_name'        => $row['display_name'] ?: $row['user_login'],
                'user_handle'      => '@' . $row['user_nicename'],
                'balance'          => $earned,
                'points'           => (float) $earned,
                'points_formatted' => $mycred->format_creds( $earned )
            );
        }
    }

    return $members;
}

function handle_points_adjustment( WP_REST_Request $request, $mode = 'award' ) {
    if ( ! function_exists( 'mycred_add' ) ) {
        return new WP_Error( 'mycred_unavailable', __( 'myCRED core functions are not available.', 'mycred' ), array( 'status' => 500 ) );
    }

    $mode = ( $mode === 'deduct' ) ? 'deduct' : 'award';

    $point_type = $request->get_param( 'point_type' );
    $point_type = $point_type ? sanitize_key( $point_type ) : 'mycred_default';

    $available_types = function_exists( 'mycred_get_types' ) ? mycred_get_types() : array();
    if ( $point_type && ! empty( $available_types ) && ! isset( $available_types[ $point_type ] ) ) {
        return new WP_Error( 'invalid_point_type', __( 'Invalid point type.', 'mycred' ), array( 'status' => 400 ) );
    }

    $amount = $request->get_param( 'amount' );
    if ( ! is_numeric( $amount ) || $amount <= 0 ) {
        return new WP_Error( 'invalid_amount', __( 'Amount must be greater than zero.', 'mycred' ), array( 'status' => 400 ) );
    }
    $amount = (float) $amount;

    $apply_to = $request->get_param( 'apply_to' );
    $apply_to = is_string( $apply_to ) ? strtolower( $apply_to ) : '';
    $apply_all = ( 'all' === $apply_to );

    if ( $apply_all ) {
        $user_query = new WP_User_Query( array(
            'fields'  => 'ID',
            'number'  => -1,
            'orderby' => 'ID',
            'order'   => 'ASC',
            'blog_id' => get_current_blog_id(),
        ) );
        $user_ids = array_map( 'absint', (array) $user_query->get_results() );
    } else {
        $user_ids = $request->get_param( 'user_ids' );
        if ( ! is_array( $user_ids ) ) {
            if ( is_scalar( $user_ids ) ) {
                $user_ids = array( $user_ids );
            } else {
                $user_ids = array();
            }
        }
        $user_ids = array_unique( array_map( 'absint', (array) $user_ids ) );
    }

    $user_ids = array_filter( $user_ids );
    if ( empty( $user_ids ) ) {
        $error_message = $apply_all
            ? __( 'No users available for adjustment.', 'mycred' )
            : __( 'Select at least one user.', 'mycred' );
        return new WP_Error( 'invalid_users', $error_message, array( 'status' => 400 ) );
    }

    $message_param = $request->get_param( 'message' );
    if ( '' === $message_param && $request->has_param( 'log_entry' ) ) {
        $message_param = $request->get_param( 'log_entry' );
    }
    $entry_message = is_string( $message_param ) ? sanitize_text_field( $message_param ) : '';
    if ( '' === $entry_message ) {
        $entry_message = ( $mode === 'deduct' )
            ? __( 'Points deducted via dashboard quick action.', 'mycred' )
            : __( 'Points awarded via dashboard quick action.', 'mycred' );
    }

    $reference = ( $mode === 'deduct' ) ? 'dashboard_quick_deduct' : 'dashboard_quick_award';

    $processed = array();
    $failed = array();

    foreach ( $user_ids as $user_id ) {
        $user = get_user_by( 'id', $user_id );
        if ( ! $user ) {
            $failed[] = array(
                'id'     => $user_id,
                'reason' => 'not_found',
            );
            continue;
        }

        $result = mycred_add(
            $reference,
            $user_id,
            ( $mode === 'deduct' ) ? -1 * $amount : $amount,
            $entry_message,
            0,
            array( 'source' => 'dashboard_quick_action' ),
            $point_type
        );

        if ( false === $result ) {
            $failed[] = array(
                'id'     => $user_id,
                'reason' => 'rejected',
            );
            continue;
        }

        $balance = null;
        if ( function_exists( 'mycred_get_users_cred' ) ) {
            $balance = mycred_get_users_cred( $user_id, $point_type );
        } elseif ( function_exists( 'mycred_get_users_balance' ) ) {
            $balance = mycred_get_users_balance( $user_id, $point_type );
        }

        $processed[] = array(
            'id'      => $user_id,
            'balance' => $balance,
        );
    }

    $processed_count = count( $processed );
    $failed_count    = count( $failed );

    if ( $failed_count ) {
        if ( $apply_all ) {
            $response_message = sprintf(
                ( $mode === 'deduct' )
                    ? __( 'Deducted %1$s points from all users; %2$d request(s) failed.', 'mycred' )
                    : __( 'Awarded %1$s points to all users; %2$d request(s) failed.', 'mycred' ),
                $amount,
                $failed_count
            );
        } else {
            $response_message = sprintf(
                ( $mode === 'deduct' )
                    ? __( 'Deducted %1$s points from %2$d user(s); %3$d request(s) failed.', 'mycred' )
                    : __( 'Awarded %1$s points to %2$d user(s); %3$d request(s) failed.', 'mycred' ),
                $amount,
                $processed_count,
                $failed_count
            );
        }
    } else {
        if ( $apply_all ) {
            $response_message = sprintf(
                ( $mode === 'deduct' )
                    ? __( 'Deducted %1$s points from all users (%2$d processed).', 'mycred' )
                    : __( 'Awarded %1$s points to all users (%2$d processed).', 'mycred' ),
                $amount,
                $processed_count
            );
        } else {
            $response_message = sprintf(
                ( $mode === 'deduct' )
                    ? __( 'Deducted %1$s points from %2$d user(s).', 'mycred' )
                    : __( 'Awarded %1$s points to %2$d user(s).', 'mycred' ),
                $amount,
                $processed_count
            );
        }
    }

    $response = array(
        'success'   => empty( $failed ),
        'processed' => $processed,
        'failed'    => $failed,
        'message'   => $response_message,
        'apply_to'  => $apply_all ? 'all' : 'selection',
    );

    return rest_ensure_response( $response );
}

function mycred_dashboard_calculate_percentage_change( $old_value, $new_value ) {
    $old_value = (float) $old_value;
    $new_value = (float) $new_value;

    if ( $old_value == 0 ) {
        // If old value is 0, we can't calculate percentage
        // If new value > 0, it's a new increase, show as +100%
        // If new value is also 0, show as 0%
        if ( $new_value > 0 ) {
            return '+100%';
        } else {
            return '0%';
        }
    }

    $difference = $new_value - $old_value;
    $percentage = ( $difference / $old_value ) * 100;

    // Format the percentage
    if ( $percentage > 0 ) {
        return '+' . number_format( $percentage, 1 ) . '%';
    } elseif ( $percentage < 0 ) {
        return number_format( $percentage, 1 ) . '%';
    } else {
        return '0%';
    }
}

function mycred_dashboard_format_user( WP_User $user, $with_details = false, $point_type = NULL ) {
    $data = array(
        'id'     => (int) $user->ID,
        'name'   => $user->display_name ?: $user->user_login,
        'handle' => '@' . $user->user_nicename,
        'email'  => $user->user_email,
    );

    if ( $with_details ) {
        $data['roles'] = (array) $user->roles;
        $data['registered'] = $user->user_registered; // MySQL datetime (UTC)

        // Try to get balance for configured default point type
        $default_type = 'mycred_default';
        
        if ( ! empty( $point_type ) ) {
            $default_type = sanitize_key( $point_type );
        } else {
            $settings = mycred_get_option( 'mycred_pref_core' );
            if ( ! empty( $settings['dashboard']['dashboard_default_point'] ) ) {
                $default_type = sanitize_key( $settings['dashboard']['dashboard_default_point'] );
            }
        }

        $balance = 0;
        if ( function_exists( 'mycred_get_users_cred' ) ) {
            $balance = mycred_get_users_cred( $user->ID, $default_type );
        } elseif ( function_exists( 'mycred_get_users_balance' ) ) {
            $balance = mycred_get_users_balance( $user->ID, $default_type );
        }

        $data['point_type'] = $default_type;
        $data['balance']    = (float) $balance;
    }

    return $data;
}




