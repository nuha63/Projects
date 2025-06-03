<?php
include 'config.php';
session_start();
include 'user_header.php';

$user_id = $_SESSION['user_id'] ?? 0;
if (!$user_id) {
    header('location:login.php');
    exit;
}

// Handle session message
$message = [];
if (isset($_SESSION['message'])) {
    $message[] = $_SESSION['message'];
    unset($_SESSION['message']);
}

// Handle review submission or update
if (isset($_POST['submit_review'])) {
    $book_id = $_POST['book_id'] !== '' ? (int)$_POST['book_id'] : 'NULL';
    $review_text = mysqli_real_escape_string($conn, $_POST['review_text']);
    $rating = (int)$_POST['rating'];

    if (isset($_POST['review_id']) && $_POST['review_id'] !== '') {
        // Update existing review
        $review_id = (int)$_POST['review_id'];
        mysqli_query($conn, "UPDATE reviews SET book_id=$book_id, review_text='$review_text', rating=$rating WHERE id=$review_id AND user_id=$user_id") or die('Update failed');
        $_SESSION['message'] = 'Review updated successfully!';
    } else {
        // Insert new review
        mysqli_query($conn, "INSERT INTO reviews (user_id, book_id, review_text, rating) VALUES ($user_id, $book_id, '$review_text', $rating)") or die('Insert failed');
        $_SESSION['message'] = 'Review submitted successfully!';
    }

    header("Location: review.php");
    exit;
}

// Handle delete request
if (isset($_GET['delete'])) {
    $delete_id = (int)$_GET['delete'];
    mysqli_query($conn, "DELETE FROM reviews WHERE id=$delete_id AND user_id=$user_id") or die('Delete failed');
    $_SESSION['message'] = 'Review deleted successfully!';
    header("Location: review.php");
    exit;
}

// Handle edit request
$edit_review = null;
if (isset($_GET['edit'])) {
    $edit_id = (int)$_GET['edit'];
    $result = mysqli_query($conn, "SELECT * FROM reviews WHERE id=$edit_id AND user_id=$user_id LIMIT 1");
    if (mysqli_num_rows($result) > 0) {
        $edit_review = mysqli_fetch_assoc($result);
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Submit & View Reviews</title>
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="review.css">
</head>
<body>

<?php
if (!empty($message)) {
    foreach ($message as $msg) {
        echo "<div class='message'>$msg</div>";
    }
}
?>

<!-- Review Form -->
<div class="review-form-container">
    <h2><?= $edit_review ? 'Edit Your Review' : 'Submit a Review' ?></h2>
    <form action="" method="POST">
        <input type="hidden" name="review_id" value="<?= $edit_review['id'] ?? '' ?>">
        <label>Book (optional):
            <select name="book_id">
                <option value="">Site Review</option>
                <?php
                $books = mysqli_query($conn, "SELECT * FROM products");
                while ($book = mysqli_fetch_assoc($books)) {
                    $selected = isset($edit_review['book_id']) && $edit_review['book_id'] == $book['id'] ? 'selected' : '';
                    echo "<option value='{$book['id']}' $selected>{$book['name']}</option>";
                }
                ?>
            </select>
        </label>

        <label>Rating (1 to 5):</label>
        <input type="number" name="rating" min="1" max="5" required value="<?= $edit_review['rating'] ?? '' ?>">

        <label>Your Review:</label>
        <textarea name="review_text" rows="5" required><?= $edit_review['review_text'] ?? '' ?></textarea>

        <input type="submit" name="submit_review" value="<?= $edit_review ? 'Update Review' : 'Submit Review' ?>">
    </form>
</div>

<!-- Display Reviews -->
<h2 class="section-title">User Reviews</h2>
<?php
$reviews = mysqli_query($conn, "SELECT r.*, p.name AS book_name, u.name AS user_name FROM reviews r
    LEFT JOIN products p ON r.book_id = p.id
    JOIN register u ON r.user_id = u.id
    ORDER BY r.created_at DESC") or die('Query failed');

while ($r = mysqli_fetch_assoc($reviews)) {
    echo "<div class='review-box'>";
    echo "<strong>{$r['user_name']}</strong> ";
    echo "<span>rated {$r['rating']}/5</span><br>";
    echo $r['book_name'] ? "<em>Book: {$r['book_name']}</em><br>" : "<em>Site Review</em><br>";
    echo "<p>{$r['review_text']}</p>";

    if ($r['user_id'] == $user_id) {
        echo "<div class='review-actions'>";
        echo "<a href='review.php?edit={$r['id']}' class='btn-edit'>Edit</a> ";
        echo "<a href='review.php?delete={$r['id']}' class='btn-delete' onclick=\"return confirm('Delete this review?');\">Delete</a>";
        echo "</div>";
    }

    echo "</div>";
}
?>

<?php include 'footer.php'; ?>

</body>
</html>
