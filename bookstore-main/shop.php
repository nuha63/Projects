<?php
include 'config.php';
session_start();

$user_id = $_SESSION['user_id'];

if (!isset($user_id)) {
    header('location:login.php');
    exit;
}

if (isset($_POST['add_to_cart'])) {
    $pro_pid = intval($_POST['product_id']);
    $pro_name = mysqli_real_escape_string($conn, $_POST['product_name']);
    $pro_price = floatval($_POST['product_price']);
    $pro_quantity = intval($_POST['product_quantity']);
    $pro_image = mysqli_real_escape_string($conn, $_POST['product_image']);

    $check = mysqli_query($conn, "SELECT * FROM `cart` WHERE pid='$pro_pid' AND user_id='$user_id'") or die('Query failed');

    if (mysqli_num_rows($check) > 0) {
        $message[] = 'Product already added to cart!';
    } else {
        mysqli_query($conn, "INSERT INTO `cart`(user_id, pid, name, price, quantity, image) 
        VALUES ('$user_id', '$pro_pid', '$pro_name', '$pro_price', '$pro_quantity', '$pro_image')") or die('Insert failed');
        $message[] = 'Product added to cart!';
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Shop Page</title>

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="home.css">
</head>
<body>

<?php include 'user_header.php'; ?>

<?php
if (isset($message) && is_array($message)) {
   foreach ($message as $msg) {
      echo '<div class="message"><span>' . $msg . '</span><i class="fas fa-times" onclick="this.parentElement.remove();"></i></div>';
   }
}
?>

<section class="products_cont">
    <div class="pro_box_cont">
        <?php
        $select_products = mysqli_query($conn, "SELECT * FROM `products`") or die('Query failed');

        if (mysqli_num_rows($select_products) > 0) {
            while ($fetch_products = mysqli_fetch_assoc($select_products)) {
        ?>
        <form action="" method="post" class="pro_box">
            <img src="./uploaded_img/<?php echo $fetch_products['image']; ?>" alt="Product Image">
            
            <h3><?php echo $fetch_products['name']; ?></h3>
            <p class="product_price">TK <?php echo $fetch_products['price']; ?> /-</p>
            <p class="product_writer">By: <?php echo $fetch_products['writer']; ?></p>
            <p class="product_category">Category: <?php echo $fetch_products['category']; ?></p>

            <?php if ($fetch_products['quantity'] <= 0): ?>
                <p class="stock_status" style="color: red; font-weight: bold;">Out of Stock</p>
                <input type="number" value="0" disabled class="quantity_input">
                <input type="submit" value="Unavailable" disabled class="product_btn disabled_btn">
            <?php else: ?>
                <input type="hidden" name="product_id" value="<?php echo $fetch_products['id']; ?>">
                <input type="hidden" name="product_name" value="<?php echo $fetch_products['name']; ?>">
                <input type="hidden" name="product_price" value="<?php echo $fetch_products['price']; ?>">
                <input type="hidden" name="product_image" value="<?php echo $fetch_products['image']; ?>">

                <input type="number" name="product_quantity" min="1" value="1" class="quantity_input">
                <input type="submit" name="add_to_cart" value="Add to Cart" class="product_btn">
            <?php endif; ?>
        </form>
        <?php
            }
        } else {
            echo '<p class="empty">No Products Added Yet!</p>';
        }
        ?>
    </div>
</section>

<?php include 'footer.php'; ?>

<script src="https://kit.fontawesome.com/eedbcd0c96.js" crossorigin="anonymous"></script>
<script src="script.js"></script>

</body>
</html>
