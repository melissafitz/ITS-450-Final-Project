-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Nov 30, 2018 at 05:06 PM
-- Server version: 5.7.24-0ubuntu0.16.04.1
-- PHP Version: 7.0.32-0ubuntu0.16.04.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ecommerse2`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_customer` (IN `e` VARCHAR(80), IN `f` VARCHAR(20), IN `l` VARCHAR(40), IN `a1` VARCHAR(80), IN `a2` VARCHAR(80), IN `c` VARCHAR(60), IN `s` CHAR(2), IN `z` MEDIUMINT, IN `p` BIGINT(10), OUT `cid` INT)  BEGIN
	INSERT INTO customers VALUES (NULL, e, f, l, a1, a2, c, s, z, p, NOW());
	SELECT LAST_INSERT_ID() INTO cid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_order` (`cid` INT, `uid` CHAR(32), `ship` DECIMAL(5,2), `cc` MEDIUMINT, OUT `total` DECIMAL(7,2), OUT `oid` INT)  BEGIN
	DECLARE subtotal DECIMAL(7,2);
	INSERT INTO orders (customer_id, shipping, credit_card_number, order_date) VALUES (cid, ship, cc, NOW());
	SELECT LAST_INSERT_ID() INTO oid;
	INSERT INTO order_contents (order_id, product_type, product_id, quantity, price_per) SELECT oid, c.product_type, c.product_id, c.quantity, IFNULL(sales.price, ncp.price) FROM carts AS c INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="other" AND c.user_session_id=uid UNION SELECT oid, c.product_type, c.product_id, c.quantity, IFNULL(sales.price, sc.price) FROM carts AS c INNER JOIN specific_coffees AS sc ON c.product_id=sc.id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="coffee" AND c.user_session_id=uid;
	SELECT SUM(quantity*price_per) INTO subtotal FROM order_contents WHERE order_id=oid;
	UPDATE orders SET total = (subtotal + ship) WHERE id=oid;
	SELECT (subtotal + ship) INTO total;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_cart` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM carts WHERE user_session_id=uid AND product_type=type AND product_id=pid;
IF cid > 0 THEN
UPDATE carts SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE 
INSERT INTO carts (user_session_id, product_type, product_id, quantity) VALUES (uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_wish_list` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM wish_lists WHERE user_session_id=uid AND product_type=type AND product_id=pid;
IF cid > 0 THEN
UPDATE wish_lists SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE 
INSERT INTO wish_lists (user_session_id, product_type, product_id, quantity) VALUES (uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_transaction` (`oid` INT, `trans_type` VARCHAR(18), `amt` DECIMAL(7,2), `rc` TINYINT, `rrc` TINYTEXT, `tid` BIGINT, `r` TEXT)  BEGIN
	INSERT INTO transactions VALUES (NULL, oid, trans_type, amt, rc, rrc, tid, r, NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cart` (`uid` CHAR(32))  BEGIN
	DELETE FROM carts WHERE user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_order_contents` (`oid` INT)  BEGIN
SELECT oc.quantity, oc.price_per, (oc.quantity*oc.price_per) AS subtotal, ncc.category, ncp.name, o.total, o.shipping FROM order_contents AS oc INNER JOIN non_coffee_products AS ncp ON oc.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id INNER JOIN orders AS o ON oc.order_id=o.id WHERE oc.product_type="other" AND oc.order_id=oid UNION SELECT oc.quantity, oc.price_per, (oc.quantity*oc.price_per), gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), o.total, o.shipping FROM order_contents AS oc INNER JOIN specific_coffees AS sc ON oc.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id INNER JOIN orders AS o ON oc.order_id=o.id  WHERE oc.product_type="coffee" AND oc.order_id=oid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_shopping_cart_contents` (`uid` CHAR(32))  BEGIN
SELECT CONCAT("O", ncp.id) AS sku, c.quantity, ncc.category, ncp.name, ncp.price, ncp.stock, sales.price AS sale_price FROM carts AS c INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="other" AND c.user_session_id=uid UNION SELECT CONCAT("C", sc.id), c.quantity, gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, sales.price FROM carts AS c INNER JOIN specific_coffees AS sc ON c.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="coffee" AND c.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_wish_list_contents` (`uid` CHAR(32))  BEGIN
SELECT CONCAT("O", ncp.id) AS sku, wl.quantity, ncc.category, ncp.name, ncp.price, ncp.stock, sales.price AS sale_price FROM wish_lists AS wl INNER JOIN non_coffee_products AS ncp ON wl.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE wl.product_type="other" AND wl.user_session_id=uid UNION SELECT CONCAT("C", sc.id), wl.quantity, gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, sales.price FROM wish_lists AS wl INNER JOIN specific_coffees AS sc ON wl.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE wl.product_type="coffee" AND wl.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_cart` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT)  BEGIN
DELETE FROM carts WHERE user_session_id=uid AND product_type=type AND product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_wish_list` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT)  BEGIN
DELETE FROM wish_lists WHERE user_session_id=uid AND product_type=type AND product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_categories` (`type` VARCHAR(6))  BEGIN
IF type = 'coffee' THEN
SELECT * FROM general_coffees ORDER by category;
ELSEIF type = 'other' THEN
SELECT * FROM non_coffee_categories ORDER by category;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_products` (`type` VARCHAR(6), `cat` TINYINT)  BEGIN
IF type = 'coffee' THEN
SELECT gc.description, gc.image, CONCAT("C", sc.id) AS sku, 
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole, sc.price) AS name, 
sc.stock, sc.price, sales.price AS sale_price 
FROM specific_coffees AS sc INNER JOIN sizes AS s ON s.id=sc.size_id 
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id 
LEFT OUTER JOIN sales ON (sales.product_id=sc.id 
AND sales.product_type='coffee' AND 
((NOW() BETWEEN sales.start_date AND sales.end_date) 
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) 
WHERE general_coffee_id=cat AND stock>0 
ORDER by name;
ELSEIF type = 'other' THEN
SELECT ncc.description AS g_description, ncc.image AS g_image, 
CONCAT("O", ncp.id) AS sku, ncp.name, ncp.description, ncp.image, 
ncp.price, ncp.stock, sales.price AS sale_price
FROM non_coffee_products AS ncp INNER JOIN non_coffee_categories AS ncc 
ON ncc.id=ncp.non_coffee_category_id 
LEFT OUTER JOIN sales ON (sales.product_id=ncp.id 
AND sales.product_type='other' AND 
((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE non_coffee_category_id=cat ORDER by date_created DESC;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_sale_items` (`get_all` BOOLEAN)  BEGIN
IF get_all = 1 THEN 
SELECT CONCAT("O", ncp.id) AS sku, sa.price AS sale_price, ncc.category, ncp.image, ncp.name, ncp.price, ncp.stock, ncp.description FROM sales AS sa INNER JOIN non_coffee_products AS ncp ON sa.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id WHERE sa.product_type="other" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) )
UNION SELECT CONCAT("C", sc.id), sa.price, gc.category, gc.image, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, gc.description FROM sales AS sa INNER JOIN specific_coffees AS sc ON sa.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id WHERE sa.product_type="coffee" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) );
ELSE 
(SELECT CONCAT("O", ncp.id) AS sku, sa.price AS sale_price, ncc.category, ncp.image, ncp.name FROM sales AS sa INNER JOIN non_coffee_products AS ncp ON sa.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id WHERE sa.product_type="other" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) ) ORDER BY RAND() LIMIT 2) UNION (SELECT CONCAT("C", sc.id), sa.price, gc.category, gc.image, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole) FROM sales AS sa INNER JOIN specific_coffees AS sc ON sa.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id WHERE sa.product_type="coffee" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) ) ORDER BY RAND() LIMIT 2);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_cart` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
IF qty > 0 THEN
UPDATE carts SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND product_type=type AND product_id=pid;
ELSEIF qty = 0 THEN
CALL remove_from_cart (uid, type, pid);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_wish_list` (`uid` CHAR(32), `type` VARCHAR(6), `pid` MEDIUMINT, `qty` TINYINT)  BEGIN
IF qty > 0 THEN
UPDATE wish_lists SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND product_type=type AND product_id=pid;
ELSEIF qty = 0 THEN
CALL remove_from_wish_list (uid, type, pid);
END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE `carts` (
  `id` int(10) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','other') NOT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `carts`
--

INSERT INTO `carts` (`id`, `quantity`, `user_session_id`, `product_type`, `product_id`, `date_created`, `date_modified`) VALUES
(1, 1, '2b72e2e21782c22e7643d43b78b31c4c', 'other', 2, '2018-11-22 21:04:44', '2018-11-22 21:04:44'),
(2, 1, '30798adef3d014904dc440e0cc5a9aa9', 'other', 2, '2018-11-22 21:14:00', '2018-11-22 21:14:00'),
(3, 1, '1d6a9e332723d5e8678399047fe6209e', 'other', 2, '2018-11-23 19:16:58', '2018-11-23 19:16:58'),
(61, 1, '13342042ad05218dbeb3173c7f046ff9', 'other', 2, '2018-11-25 23:50:30', '2018-11-25 23:54:02'),
(62, 4, '13342042ad05218dbeb3173c7f046ff9', 'coffee', 1, '2018-11-26 02:04:24', '2018-11-30 01:04:00'),
(88, 2, 'a53008c60033da1e438c46a4d6de2c66', 'other', 2, '2018-12-01 01:03:01', '2018-12-01 01:03:48'),
(84, 1, '3f7669fcf2954dc3e8478e94ae3cbe85', 'other', 2, '2018-11-30 23:48:17', '2018-11-30 23:48:24');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(10) UNSIGNED NOT NULL,
  `email` varchar(80) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(40) NOT NULL,
  `address1` varchar(80) NOT NULL,
  `address2` varchar(80) DEFAULT NULL,
  `city` varchar(60) NOT NULL,
  `state` char(2) NOT NULL,
  `zip` mediumint(5) UNSIGNED ZEROFILL NOT NULL,
  `phone` bigint(10) NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `general_coffees`
--

CREATE TABLE `general_coffees` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `category` varchar(40) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `general_coffees`
--

INSERT INTO `general_coffees` (`id`, `category`, `description`, `image`) VALUES
(1, 'Monopoly', 'This is a description.', 'monopoly.jpeg'),
(2, 'Clue', 'This is a description.', 'clue.jpeg'),
(3, 'Life', 'This is a description.', 'life.jpeg');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_categories`
--

CREATE TABLE `non_coffee_categories` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `category` varchar(40) NOT NULL,
  `description` tinytext NOT NULL,
  `image` varchar(45) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `non_coffee_categories`
--

INSERT INTO `non_coffee_categories` (`id`, `category`, `description`, `image`) VALUES
(1, 'Card Games', 'This is a description.', 'cards.jpg'),
(2, 'Kids Games', 'This is a description.', 'kids.jpg'),
(3, 'RPG Games', 'This is a description.', 'rpg.jpg'),
(4, 'Word Games', 'This is a description.', 'word.png');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_products`
--

CREATE TABLE `non_coffee_products` (
  `id` mediumint(8) UNSIGNED NOT NULL,
  `non_coffee_category_id` tinyint(3) UNSIGNED NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL,
  `price` decimal(5,2) UNSIGNED NOT NULL,
  `stock` mediumint(8) UNSIGNED NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `non_coffee_products`
--

INSERT INTO `non_coffee_products` (`id`, `non_coffee_category_id`, `name`, `description`, `image`, `price`, `stock`, `date_created`) VALUES
(1, 1, 'Cards Against Humanity', 'This is a description.', 'cah.jpg', '20.95', 110, '2010-08-15 19:22:35'),
(4, 2, 'Mouse Trap', 'This is a description.', 'mousetrap.jpg', '8.00', 33, '2018-11-30 00:29:58'),
(2, 1, 'Old Maid', 'This is a description.', 'oldmaid.jpg', '7.95', 21, '2010-08-18 23:00:59'),
(3, 2, 'Guess Who', 'This is a description.', 'guesswho.jpg', '13.12', 24, '2018-11-30 00:28:51'),
(5, 3, 'Battleship', 'This is a description.', 'battleship.jpeg', '16.50', 45, '2018-11-30 00:31:06'),
(6, 4, 'Scrabble', 'This is a description.', 'scrabble.jpeg', '13.00', 200, '2018-11-30 00:35:55');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_id` int(10) UNSIGNED NOT NULL,
  `total` decimal(7,2) UNSIGNED DEFAULT NULL,
  `shipping` decimal(5,2) UNSIGNED NOT NULL,
  `credit_card_number` mediumint(4) UNSIGNED NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `order_contents`
--

CREATE TABLE `order_contents` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `product_type` enum('coffee','other','sale') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `price_per` decimal(5,2) UNSIGNED NOT NULL,
  `ship_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

CREATE TABLE `sales` (
  `id` int(10) UNSIGNED NOT NULL,
  `product_type` enum('coffee','other') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `price` decimal(5,2) UNSIGNED NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sales`
--

INSERT INTO `sales` (`id`, `product_type`, `product_id`, `price`, `start_date`, `end_date`) VALUES
(1, 'other', 1, '5.00', '2010-08-16', '2010-09-30'),
(2, 'coffee', 7, '7.00', '2010-08-19', NULL),
(3, 'coffee', 9, '13.00', '2010-08-19', '2010-09-29'),
(4, 'other', 2, '7.00', '2010-08-22', NULL),
(5, 'coffee', 8, '13.00', '2010-08-22', '2010-09-30'),
(6, 'coffee', 10, '30.00', '2010-08-22', '2010-09-30');

-- --------------------------------------------------------

--
-- Table structure for table `sizes`
--

CREATE TABLE `sizes` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `size` varchar(40) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sizes`
--

INSERT INTO `sizes` (`id`, `size`) VALUES
(1, 'Regular');

-- --------------------------------------------------------

--
-- Table structure for table `specific_coffees`
--

CREATE TABLE `specific_coffees` (
  `id` mediumint(8) UNSIGNED NOT NULL,
  `general_coffee_id` tinyint(3) UNSIGNED NOT NULL,
  `size_id` tinyint(3) UNSIGNED NOT NULL,
  `caf_decaf` enum('caf','decaf','boardGames','other') DEFAULT NULL,
  `ground_whole` enum('ground','whole','limitedEdition','regular') DEFAULT NULL,
  `price` decimal(5,2) UNSIGNED NOT NULL,
  `stock` mediumint(8) UNSIGNED NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `specific_coffees`
--

INSERT INTO `specific_coffees` (`id`, `general_coffee_id`, `size_id`, `caf_decaf`, `ground_whole`, `price`, `stock`, `date_created`) VALUES
(8, 2, 1, NULL, NULL, '15.00', 24, '2010-08-16 09:15:54'),
(2, 3, 1, NULL, NULL, '12.00', 27, '2010-08-16 09:15:54'),
(1, 1, 1, NULL, NULL, '14.00', 33, '2010-08-16 09:15:54');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `type` varchar(18) NOT NULL,
  `amount` decimal(7,2) NOT NULL,
  `response_code` tinyint(1) UNSIGNED NOT NULL,
  `response_reason` tinytext,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `response` text NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `created_at`) VALUES
(1, 'test', '$2y$10$mruVDeeujxO9.2aK6WjjQecaplqbjDF6yJLTEX4yNLw.iIKQYfIDS', '2018-11-28 15:52:43');

-- --------------------------------------------------------

--
-- Table structure for table `wish_lists`
--

CREATE TABLE `wish_lists` (
  `id` int(10) UNSIGNED NOT NULL,
  `quantity` tinyint(3) UNSIGNED NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','other','sale') DEFAULT NULL,
  `product_id` mediumint(8) UNSIGNED NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `wish_lists`
--

INSERT INTO `wish_lists` (`id`, `quantity`, `user_session_id`, `product_type`, `product_id`, `date_created`, `date_modified`) VALUES
(29, 6, 'bdbf404aeb5684da5c84cd08a7a33b34', 'coffee', 1, '2018-11-30 19:33:58', '2018-11-30 20:11:01'),
(28, 1, 'bdbf404aeb5684da5c84cd08a7a33b34', 'coffee', 8, '2018-11-30 19:33:32', '2018-11-30 19:34:05'),
(30, 1, '3f7669fcf2954dc3e8478e94ae3cbe85', 'coffee', 12, '2018-11-30 22:08:46', '2018-11-30 22:08:46'),
(27, 2, 'bdbf404aeb5684da5c84cd08a7a33b34', 'coffee', 2, '2018-11-30 19:33:20', '2018-11-30 19:34:05');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_type` (`product_type`,`product_id`),
  ADD KEY `user_session_id` (`user_session_id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `general_coffees`
--
ALTER TABLE `general_coffees`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `type` (`category`);

--
-- Indexes for table `non_coffee_categories`
--
ALTER TABLE `non_coffee_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `category` (`category`);

--
-- Indexes for table `non_coffee_products`
--
ALTER TABLE `non_coffee_products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `non_coffee_category_id` (`non_coffee_category_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `order_date` (`order_date`);

--
-- Indexes for table `order_contents`
--
ALTER TABLE `order_contents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ship_date` (`ship_date`),
  ADD KEY `product_type` (`product_type`,`product_id`);

--
-- Indexes for table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `start_date` (`start_date`),
  ADD KEY `product_type` (`product_type`,`product_id`);

--
-- Indexes for table `sizes`
--
ALTER TABLE `sizes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `size` (`size`);

--
-- Indexes for table `specific_coffees`
--
ALTER TABLE `specific_coffees`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_coffee_id` (`general_coffee_id`),
  ADD KEY `size` (`size_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `wish_lists`
--
ALTER TABLE `wish_lists`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_type` (`product_type`,`product_id`),
  ADD KEY `user_session_id` (`user_session_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `carts`
--
ALTER TABLE `carts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;
--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=66;
--
-- AUTO_INCREMENT for table `general_coffees`
--
ALTER TABLE `general_coffees`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `non_coffee_categories`
--
ALTER TABLE `non_coffee_categories`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `non_coffee_products`
--
ALTER TABLE `non_coffee_products`
  MODIFY `id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `order_contents`
--
ALTER TABLE `order_contents`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `sizes`
--
ALTER TABLE `sizes`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `specific_coffees`
--
ALTER TABLE `specific_coffees`
  MODIFY `id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=77;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `wish_lists`
--
ALTER TABLE `wish_lists`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
