import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);
window.supabase = supabase;

async function syncData() {
  if (window.STATE && window.renderAllDonations) {
    const { data, error } = await supabase.from('donations').select('*');
    if (data && !error && data.length > 0) {
      window.STATE.donations = data;
      window.STATE.stats.count = data.length;
      window.STATE.stats.kg = data.reduce((a,c) => a + Number(c.qty||0), 0);
      window.STATE.stats.meals = data.reduce((a,c) => a + Number(c.portions||0), 0);
      
      // Update UI if methods exist
      if (typeof window.renderAllDonations === 'function') window.renderAllDonations(window.STATE.activeFilter || 'all');
      if (typeof window.renderRecentDonations === 'function') window.renderRecentDonations();
      if (typeof window.renderStats === 'function') window.renderStats();
    }
  }
}

// Automatically sync when the module loads
syncData();
