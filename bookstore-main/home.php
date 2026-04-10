<?php
include 'config.php';
session_start();

$user_id = isset($_SESSION['user_id']) ? $_SESSION['user_id'] : null;

if (isset($_POST['add_to_cart'])) {
  if (!$user_id) {
    $message[] = 'Please login to add items to cart!';
  } else {
    $pro_name = $_POST['product_name'];
    $pro_price = $_POST['product_price'];
    $pro_quantity = $_POST['product_quantity'];
    $pro_image = $_POST['product_image'];

    $check = mysqli_query($conn, "SELECT * FROM cart WHERE name='$pro_name' AND user_id='$user_id'") or die('query failed');

    if (mysqli_num_rows($check) > 0) {
      $message[] = 'Already added to cart!';
    } else {
      mysqli_query($conn, "INSERT INTO cart (user_id, name, price, quantity, image) VALUES ('$user_id','$pro_name','$pro_price','$pro_quantity','$pro_image')") or die('query2 failed');
      $message[] = 'Product added to cart!';
    }
  }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Home Page</title>

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" crossorigin="anonymous" />
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="home.css">
</head>
<body>
<?php include 'user_header.php'; ?>

<section class="home_cont">
  <div class="main_descrip">
    <h1>Bookie</h1>
    <p>Explore, Discover, and Buy Your Favorite Books</p>
    <button>Discover More</button>
  </div>
</section>

<section class="products_cont">
  <div class="pro_box_cont">
    <?php
    $select_products = mysqli_query($conn, "SELECT * FROM products LIMIT 5") or die('query failed');

    if (mysqli_num_rows($select_products) > 0) {
      while ($fetch_products = mysqli_fetch_assoc($select_products)) {
    ?>
    <form action="" method="post" class="pro_box">
      <img src="./uploaded_img/<?php echo $fetch_products['image']; ?>" alt="">
      <h3><?php echo $fetch_products['name']; ?></h3>
      <p class="product_price">TK <?php echo $fetch_products['price']; ?> /-</p>
      <p class="product_writer">By: <?php echo $fetch_products['writer']; ?></p>
      <p class="product_category">Category: <?php echo $fetch_products['category']; ?></p>

      <?php if ($fetch_products['quantity'] <= 0): ?>
        <p class="stock_status" style="color: red; font-weight: bold;">Out of Stock</p>
        <input type="number" value="0" disabled class="quantity_input">
        <input type="submit" value="Unavailable" disabled class="product_btn disabled_btn">
      <?php else: ?>
        <input type="hidden" name="product_name" value="<?php echo $fetch_products['name']; ?>">
        <input type="hidden" name="product_price" value="<?php echo $fetch_products['price']; ?>">
        <input type="hidden" name="product_image" value="<?php echo $fetch_products['image']; ?>">

        <input type="number" name="product_quantity" min="1" value="1" class="quantity_input">
        <input type="submit" value="Add to Cart" name="add_to_cart" class="product_btn">
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

<section class="about_cont">
  <img src="about.jpg" alt="">
  <div class="about_descript">
    <h2>Discover Our Story</h2>
    <p>At Bookiee, we are passionate about connecting readers with captivating stories, inspiring ideas, and a world of knowledge. Our bookstore is more than just a place to buy books; it's a haven for book enthusiasts, where the love for literature thrives.</p>
    <button class="product_btn" onclick="window.location.href='about.php';">Read More</button>
  </div>
</section>

<section class="questions_cont">
  <div class="questions">
    <h2>Have Any Queries?</h2>
    <p>At Bookiee, we value your satisfaction and strive to provide exceptional customer service. If you have any questions, concerns, or inquiries, our dedicated team is here to assist you every step of the way.</p>
    <button class="product_btn" onclick="window.location.href='contact.php';">Contact Us</button>
  </div>
</section>

<?php include 'footer.php'; ?>
<script src="https://kit.fontawesome.com/eedbcd0c96.js" crossorigin="anonymous"></script>
<script src="script.js"></script>
</body>
</html>
