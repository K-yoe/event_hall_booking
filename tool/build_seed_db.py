"""
Generates a prebuilt SQLite database (assets/databases/event_hall.db) that
already contains all the app's data. Run with:  python tool/build_seed_db.py

The schema here MUST match lib/services/database_helper.dart.
"""
import os
import sqlite3
from datetime import datetime

OUT_DIR = os.path.join("assets", "databases")
OUT_PATH = os.path.join(OUT_DIR, "event_hall.db")

MONTHS = {
    "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
    "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
}


def ts(date_str):
    """millisecondsSinceEpoch for a 'd MMM yyyy' string (local-ish, hour 10)."""
    day, mon, year = date_str.split(" ")
    dt = datetime(int(year), MONTHS[mon], int(day), 10, 0, 0)
    return int(dt.timestamp() * 1000)


HALLS = [
    ("Grand Ballroom A", "Event Hall", "KL City", 500, 4.8, 124, 2500.0, 0.0,
     "RM 2,500/day", "Available", "success", 1,
     "📽 Projector|🎤 PA System|❄️ AC|🅿️ Parking",
     "Elegant grand ballroom ideal for weddings, galas and large corporate events.",
     "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=1000"),
    ("Executive Boardroom", "Conference", "Petaling Jaya", 20, 4.6, 58, 0.0, 350.0,
     "RM 350/hr", "Limited", "warning", 1,
     "📺 TV Screen|☕ Coffee|🌐 WiFi",
     "Premium executive boardroom for high-level meetings and presentations.",
     "https://images.unsplash.com/photo-1431540015161-0bf868a2d407?q=80&w=1000"),
    ("Training Room B", "Training", "KLCC", 40, 4.5, 73, 0.0, 180.0,
     "RM 180/hr", "Available", "success", 1,
     "💻 Computers|📽 Projector|❄️ AC",
     "Fully-equipped training room with workstations for workshops and courses.",
     "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?q=80&w=1000"),
    ("Banquet Hall Omega", "Banquet", "Ampang", 300, 4.7, 96, 1800.0, 0.0,
     "RM 1,800/day", "Available", "success", 1,
     "🍽 Catering|🎵 Sound System|🅿️ Parking",
     "Spacious banquet hall with in-house catering for celebrations and dinners.",
     "https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?q=80&w=1000"),
    ("Crystal Meeting Room", "Conference", "Mont Kiara", 12, 4.4, 41, 0.0, 200.0,
     "RM 200/hr", "Available", "success", 1,
     "📺 TV|☕ Coffee|🌐 WiFi",
     "Bright, modern meeting room perfect for small team discussions.",
     "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1000"),
]

BOOKINGS = [
    ("BK-20250415-0032", "", "Grand Ballroom A", "Ahmad Hassan", "ahmad@example.com",
     "15 Apr 2025", "10:00–12:00", 11600.0, "Confirmed", 1, ts("15 Apr 2025")),
    ("BK-20250422-0019", "", "Executive Boardroom", "Siti Nora", "siti@example.com",
     "22 Apr 2025", "14:00–16:00", 700.0, "Pending", 1, ts("22 Apr 2025")),
    ("BK-20250301-0008", "", "Training Room B", "David Lim", "david@example.com",
     "1 Mar 2025", "9:00–12:00", 540.0, "Completed", 0, ts("1 Mar 2025")),
    ("BK-20250210-0003", "", "Banquet Hall Omega", "Nurul Ain", "nurul@example.com",
     "10 Feb 2025", "18:00–22:00", 3200.0, "Cancelled", 0, ts("10 Feb 2025")),
    ("BK-20250501-0041", "", "Grand Ballroom A", "Kevin Tan", "kevin@example.com",
     "1 May 2025", "8:00–12:00", 5400.0, "Pending", 1, ts("1 May 2025")),
    ("BK-20250215-0004", "", "Executive Boardroom", "Nurul Ain", "nurul@example.com",
     "15 Feb 2025", "11:00–13:00", 700.0, "Cancelled", 0, ts("15 Feb 2025")),
    ("BK-20250110-0012", "", "Banquet Hall Omega", "Ahmad Hassan", "ahmad@example.com",
     "10 Jan 2025", "18:00–23:00", 3200.0, "Completed", 0, ts("10 Jan 2025")),
    ("BK-20250602-0050", "", "Crystal Meeting Room", "Kevin Tan", "kevin@example.com",
     "2 Jun 2025", "9:00–11:00", 400.0, "Pending", 1, ts("2 Jun 2025")),
]

PAYMENTS = [
    ("TXN-20250415-8821", "BK-20250415-0032", "Ahmad Hassan", "ahmad@example.com",
     "Grand Ballroom A", 11600.0, "Maybank FPX", "Paid", "15 Apr 2025, 9:43 AM", ts("15 Apr 2025")),
    ("TXN-20250422-1102", "BK-20250422-0019", "Siti Nora", "siti@example.com",
     "Executive Boardroom", 700.0, "Credit Card", "Pending", "22 Apr 2025, 2:10 PM", ts("22 Apr 2025")),
    ("TXN-20250501-3341", "BK-20250501-0041", "Kevin Tan", "kevin@example.com",
     "Grand Ballroom A", 5400.0, "GrabPay", "Paid", "1 May 2025, 11:30 AM", ts("1 May 2025")),
    ("TXN-20250301-4412", "BK-20250301-0008", "David Lim", "david@example.com",
     "Training Room B", 540.0, "Credit Card", "Refunded", "1 Mar 2025, 8:10 AM", ts("1 Mar 2025")),
    ("TXN-20250215-2201", "BK-20250215-0004", "Nurul Ain", "nurul@example.com",
     "Executive Boardroom", 700.0, "TNG eWallet", "Failed", "15 Feb 2025, 11:00 AM", ts("15 Feb 2025")),
    ("TXN-20250110-1901", "BK-20250110-0012", "Ahmad Hassan", "ahmad@example.com",
     "Banquet Hall Omega", 3200.0, "GrabPay", "Paid", "10 Jan 2025, 2:15 PM", ts("10 Jan 2025")),
    ("TXN-20250602-9910", "BK-20250602-0050", "Kevin Tan", "kevin@example.com",
     "Crystal Meeting Room", 400.0, "Bank Transfer", "Pending", "2 Jun 2025, 9:00 AM", ts("2 Jun 2025")),
]

USERS = [
    ("Ahmad Hassan", "ahmad@example.com", "+60 12 345 6789", "user", 3, "RM 12,840",
     "Active", "AH", 0xFFE6F1FB, 0xFF0C447C, "12 Jan 2025"),
    ("Siti Nora", "siti@example.com", "+60 11 234 5678", "user", 1, "RM 700",
     "Active", "SN", 0xFFFBEAF0, 0xFF72243E, "20 Feb 2025"),
    ("David Lim", "david@example.com", "+60 16 789 0123", "user", 5, "RM 8,200",
     "Suspended", "DL", 0xFFF1EFE8, 0xFF444441, "5 Dec 2024"),
    ("Nurul Ain", "nurul@example.com", "+60 19 456 7890", "user", 2, "RM 4,400",
     "Active", "NA", 0xFFEAF3DE, 0xFF27500A, "1 Mar 2025"),
    ("Kevin Tan", "kevin@example.com", "+60 17 321 6540", "user", 0, "RM 0",
     "Active", "KT", 0xFFFAEEDA, 0xFF633806, "14 Apr 2025"),
]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    if os.path.exists(OUT_PATH):
        os.remove(OUT_PATH)

    conn = sqlite3.connect(OUT_PATH)
    c = conn.cursor()

    c.execute("""CREATE TABLE halls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, type TEXT, location TEXT,
        capacity INTEGER, rating REAL, reviewCount INTEGER,
        price_per_day REAL, price_per_hr REAL, price TEXT,
        status TEXT, statusType TEXT, isActive INTEGER,
        amenities TEXT, description TEXT, image_url TEXT)""")

    c.execute("""CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref TEXT, hallId TEXT, hallName TEXT,
        userName TEXT, userEmail TEXT,
        date TEXT, timeSlot TEXT, amount REAL,
        status TEXT, upcoming INTEGER, createdAt INTEGER)""")

    c.execute("""CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        txn TEXT, bookingRef TEXT,
        userName TEXT, userEmail TEXT, hallName TEXT,
        amount REAL, method TEXT, status TEXT,
        date TEXT, timestamp INTEGER)""")

    c.execute("""CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, email TEXT, phone TEXT, role TEXT,
        bookings INTEGER, spent TEXT, status TEXT,
        initials TEXT, avatarColor INTEGER, textColor INTEGER, joined TEXT)""")

    c.executemany(
        "INSERT INTO halls (name,type,location,capacity,rating,reviewCount,"
        "price_per_day,price_per_hr,price,status,statusType,isActive,amenities,"
        "description,image_url) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", HALLS)

    c.executemany(
        "INSERT INTO bookings (ref,hallId,hallName,userName,userEmail,date,"
        "timeSlot,amount,status,upcoming,createdAt) VALUES (?,?,?,?,?,?,?,?,?,?,?)", BOOKINGS)

    c.executemany(
        "INSERT INTO payments (txn,bookingRef,userName,userEmail,hallName,amount,"
        "method,status,date,timestamp) VALUES (?,?,?,?,?,?,?,?,?,?)", PAYMENTS)

    c.executemany(
        "INSERT INTO users (name,email,phone,role,bookings,spent,status,initials,"
        "avatarColor,textColor,joined) VALUES (?,?,?,?,?,?,?,?,?,?,?)", USERS)

    conn.commit()
    conn.close()

    size = os.path.getsize(OUT_PATH)
    print(f"Created {OUT_PATH} ({size} bytes)")
    print(f"  halls={len(HALLS)} bookings={len(BOOKINGS)} "
          f"payments={len(PAYMENTS)} users={len(USERS)}")


if __name__ == "__main__":
    main()
