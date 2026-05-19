-- Run this in your Supabase SQL Editor to create the donations table

CREATE TABLE donations (
  id text PRIMARY KEY,
  type text NOT NULL,
  qty numeric NOT NULL,
  portions integer NOT NULL,
  time text NOT NULL,
  status text NOT NULL,
  volunteer text,
  day text,
  allergens text[]
);

-- Insert some dummy data to match the UI initially
INSERT INTO donations (id, type, qty, portions, time, status, volunteer, day, allergens) VALUES
('F-1001', 'Biryani', 8, 25, '14:30', 'delivered', 'Raza M.', 'Today', ARRAY['Spicy']),
('F-1002', 'Curry', 5, 16, '12:15', 'live', 'Priya S.', 'Today', ARRAY['Dairy-free']),
('F-1003', 'Breads', 3, 10, '19:00', 'delivered', 'Arjun K.', 'Yesterday', ARRAY['Gluten']),
('F-1004', 'Salad', 2, 8, '11:00', 'delivered', 'Sneha D.', 'Yesterday', ARRAY['Vegan']),
('F-1005', 'Mixed Meal', 6, 20, '13:30', 'picked', 'Vikram P.', 'Yesterday', ARRAY[]::text[]);

-- Enable Read Access for everyone (since this is a demo)
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read access for all users" ON donations FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON donations FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON donations FOR UPDATE USING (true);
