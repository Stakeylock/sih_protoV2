import os
import json
import psycopg2
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from flask_cors import CORS
from shapely.geometry import Point, Polygon
from psycopg2.extras import Json

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# --- Database Connection ---
def get_db_connection():
    try:
        conn = psycopg2.connect(os.environ['DATABASE_URL'])
        return conn
    except psycopg2.OperationalError as e:
        print(f"Could not connect to database: {e}")
        raise

# --- Routes ---

# Add Geofence
@app.route('/geofences', methods=['POST'])
def add_geofence():
    data = request.get_json()
    
    if not data or 'name' not in data or 'area' not in data:
        return jsonify({'error': 'Missing name or area data'}), 400

    name = data['name']
    area_coords = data['area']

    if not isinstance(area_coords, list) or len(area_coords) < 3:
        return jsonify({'error': 'A polygon must have at least 3 coordinate points'}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO geofences (name, area) VALUES (%s, %s)",
            (name, Json(area_coords))
        )
        conn.commit()
        cur.close()
        conn.close()

        return jsonify({'message': 'Geofence added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get All Geofences
@app.route('/geofences', methods=['GET'])
def get_geofences():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, area FROM geofences")
        rows = cur.fetchall()
        cur.close()
        conn.close()

        geofences = []
        for row in rows:
            fence_id, name, area = row

            # If area is stringified JSON, parse it
            if isinstance(area, str):
                try:
                    area = json.loads(area)
                except json.JSONDecodeError:
                    continue  # Skip malformed

            if not isinstance(area, list):
                continue  # Skip malformed

            geofences.append({
                'id': fence_id,
                'name': name,
                'area': area
            })

        return jsonify(geofences), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Check If User Location Is Inside Any Geofence
@app.route('/check_location', methods=['POST'])
def check_location():
    data = request.get_json()

    if not data or 'latitude' not in data or 'longitude' not in data:
        return jsonify({'error': 'Missing latitude or longitude'}), 400

    user_point = Point(data['latitude'], data['longitude'])

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, area FROM geofences")
        rows = cur.fetchall()
        cur.close()
        conn.close()

        zones_inside = []
        for row in rows:
            fence_id, name, area = row

            if isinstance(area, str):
                try:
                    area = json.loads(area)
                except json.JSONDecodeError:
                    continue

            if not isinstance(area, list):
                continue

            polygon = Polygon(area)
            if polygon.contains(user_point):
                zones_inside.append({'id': fence_id, 'name': name})

        return jsonify({
            'is_inside': bool(zones_inside),
            'zones': zones_inside
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get Sample Incidents
@app.route('/incidents', methods=['GET'])
def get_incidents():
    incidents = [
        {
            "id": "1",
            "title": "Theft at City Park",
            "description": "Bag stolen",
            "severity": "High",
            "reportedAt": "10 mins ago"
        },
        {
            "id": "2",
            "title": "Suspicious Activity",
            "description": "Loitering",
            "severity": "Medium",
            "reportedAt": "30 mins ago"
        },
        {
            "id": "3",
            "title": "Lost Tourist",
            "description": "Needs help",
            "severity": "Low",
            "reportedAt": "1 hour ago"
        }
    ]
    return jsonify(incidents), 200

# --- Run the App ---
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
