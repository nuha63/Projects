<?php
include 'config.php';
session_start();

$user_id = $_SESSION['user_id'];

if (!isset($user_id)) {
    header('location:login.php');
    exit;
}

if (isset($_POST['order_btn'])) {
    $name = mysqli_real_escape_string($conn, $_POST['name']);
    $number = mysqli_real_escape_string($conn, $_POST['number']);
    $email = mysqli_real_escape_string($conn, $_POST['email']);
    $method = mysqli_real_escape_string($conn, $_POST['method']);
    $address = mysqli_real_escape_string($conn, $_POST['address']);
    $placed_on = date('d-M-Y');

    $cart_total = 0;
    $cart_products = [];
    $cart_items = [];

    // Get all cart items
    $cart_query = mysqli_query($conn, "SELECT * FROM cart WHERE user_id = '$user_id'") or die('Query failed');

    if (mysqli_num_rows($cart_query) > 0) {
        while ($item = mysqli_fetch_assoc($cart_query)) {
            $cart_items[] = $item;
            $cart_products[] = $item['name'] . ' (' . $item['quantity'] . ')';
            $cart_total += floatval($item['price']) * intval($item['quantity']);
        }
    } else {
        $message[] = 'Your cart is empty!';
    }

    $total_products = implode(', ', $cart_products);

    // Check for duplicate order
    $order_check = mysqli_query($conn, "SELECT * FROM orders WHERE 
        name = '$name' AND number = '$number' AND email = '$email' AND 
        method = '$method' AND address = '$address' AND 
        total_products = '$total_products' AND total_price = '$cart_total'") or die('Order check failed');

    if ($cart_total > 0) {
        if (mysqli_num_rows($order_check) > 0) {
            $message[] = 'Order already placed!';
        } else {
            // Insert new order
            mysqli_query($conn, "INSERT INTO orders (user_id, name, number, email, method, address, total_products, total_price, placed_on) 
            VALUES ('$user_id', '$name', '$number', '$email', '$method', '$address', '$total_products', '$cart_total', '$placed_on')") or die('Order insert failed');

            // Reduce stock in products table
            foreach ($cart_items as $item) {
                $pid = intval($item['pid']); // Correctly use pid (product ID)
                $qty = intval($item['quantity']);
                mysqli_query($conn, "UPDATE products SET quantity = quantity - $qty WHERE id = '$pid'") or die('Stock update failed');
            }

            // Clear the cart
            mysqli_query($conn, "DELETE FROM cart WHERE user_id = '$user_id'") or die('Failed to clear cart');
            $message[] = 'Order placed successfully!';
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Checkout Page</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="home.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" crossorigin="anonymous">
</head>
<body>

<?php include 'user_header.php'; ?>

<!-- Show messages -->
<?php
if (isset($message) && is_array($message)) {
    foreach ($message as $msg) {
        echo '<div class="message"><span>' . $msg . '</span><i class="fas fa-times" onclick="this.parentElement.remove();"></i></div>';
    }
}
?>


<section class="display_order">
  <h2>Ordered Products</h2>
  <?php
    $grand_total = 0;
    $select_cart = mysqli_query($conn, "SELECT * FROM cart WHERE user_id = '$user_id'") or die('Query failed');

    if (mysqli_num_rows($select_cart) > 0) {
        while ($item = mysqli_fetch_assoc($select_cart)) {
            $total_price = $item['price'] * $item['quantity'];
            $grand_total += $total_price;
  ?>
  <div class="single_order_product">
    <img src="./uploaded_img/<?php echo $item['image']; ?>" alt="">
    <div class="single_des">
      <h3><?php echo $item['name']; ?></h3>
      <p>TK <?php echo $item['price']; ?></p>
      <p>Quantity: <?php echo $item['quantity']; ?></p>
    </div>
  </div>
  <?php
        }
  ?>
  <div class="checkout_grand_total">GRAND TOTAL: <span>TK <?php echo $grand_total; ?>/-</span></div>
  <?php
    } else {
        echo '<p class="empty">Your cart is empty.</p>';
    }
  ?>
</section>

<section class="contact_us">
  <form action="" method="post">
    <h2>Add Your Details</h2>
    <input type="text" name="name" required placeholder="Enter your name">
    <input type="tel" name="number" required placeholder="Enter your number">
    <input type="email" name="email" required placeholder="Enter your email">
    <select name="method" required>
      <option value="cash on delivery">Cash on Delivery</option>
      <option value="BKash">BKash</option>
    </select>
    <textarea name="address" placeholder="Enter your address" cols="30" rows="5" required></textarea>
    <input type="submit" value="Place Your Order" name="order_btn" class="product_btn">
  </form>
</section>

<?php include 'footer.php'; ?>

<script src="https://kit.fontawesome.com/eedbcd0c96.js" crossorigin="anonymous"></script>
<script src="script.js"></script>

</body>
</html>
