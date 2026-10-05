import React, { useState, useEffect } from 'react';
import { API_BASE } from '../../config/api';

const InternalMemosPanel = ({ applicationId, onPendingMemosChange }) => {
  const [memos, setMemos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newMemoText, setNewMemoText] = useState('');
  const [editingMemoId, setEditingMemoId] = useState(null);
  const [editMemoText, setEditMemoText] = useState('');

  // Runs as soon as the panel opens. It asks the server for all the memos attached to this specific application.
  useEffect(() => {
    const fetchMemos = async () => {
      try {
        const response = await fetch(`${API_BASE}/memos/application/${applicationId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
          }
        });
        if (response.ok) {
          const data = await response.json();
          setMemos(data);
          checkPending(data);
        }
      } catch (error) {
        console.error('Failed to fetch memos:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchMemos();
  }, [applicationId]);

  // Looks through the list of memos to see if any are still 'Pending'.
  // If there are, it tells the parent component so it can lock the Approve/Reject buttons!
  const checkPending = (memosList) => {
    const hasPending = memosList.some(m => m.status === 'Pending');
    if (onPendingMemosChange) {
      onPendingMemosChange(hasPending);
    }
  };

  // Sends a brand new memo to the server.
  // It also adds it directly to the list on the screen so you don't have to refresh the page.
  const handleAddMemo = async () => {
    if (!newMemoText.trim()) return;
    
    try {
      const response = await fetch(`${API_BASE}/memos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ applicationId, memoText: newMemoText })
      });
      
      if (response.ok) {
        const newMemo = await response.json();
        const updatedMemos = [newMemo, ...memos]; // Assuming desc order
        setMemos(updatedMemos);
        setNewMemoText('');
        checkPending(updatedMemos);
      }
    } catch (error) {
      console.error('Failed to add memo:', error);
    }
  };

  // Saves the changes you made to an existing memo.
  // Great for fixing typos without having to delete and re-write the whole thing!
  const handleUpdateMemo = async (memoId) => {
    try {
      const response = await fetch(`${API_BASE}/memos/${memoId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ memoText: editMemoText })
      });
      
      if (response.ok) {
        const updatedMemos = memos.map(m => m.memoId === memoId ? { ...m, memoText: editMemoText } : m);
        setMemos(updatedMemos);
        setEditingMemoId(null);
        setEditMemoText('');
      }
    } catch (error) {
      console.error('Failed to update memo:', error);
    }
  };

  // Marks a memo as 'Resolved'.
  // This is like checking off a to-do item, letting everyone know the issue has been handled.
  const handleResolveMemo = async (memoId) => {
    try {
      const response = await fetch(`${API_BASE}/memos/${memoId}/resolve`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      
      if (response.ok) {
        const updatedMemos = memos.map(m => m.memoId === memoId ? { ...m, status: 'Resolved' } : m);
        setMemos(updatedMemos);
        checkPending(updatedMemos);
      }
    } catch (error) {
      console.error('Failed to resolve memo:', error);
    }
  };

  // Completely deletes a memo from the database forever.
  // We ask for confirmation first, just in case it was clicked by accident!
  const handleDeleteMemo = async (memoId) => {
    if (!window.confirm("Are you sure you want to completely delete this memo?")) return;
    try {
      const response = await fetch(`${API_BASE}/memos/${memoId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      
      if (response.ok) {
        const updatedMemos = memos.filter(m => m.memoId !== memoId);
        setMemos(updatedMemos);
        checkPending(updatedMemos);
      }
    } catch (error) {
      console.error('Failed to delete memo:', error);
    }
  };

  if (loading) return <div className="text-sm text-gray-500 py-4">Loading internal memos...</div>;

  return (
    <div className="bg-white border rounded-lg p-4 mt-6">
      <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center">
        <svg className="w-5 h-5 mr-2 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
        Internal Staff Memos
      </h3>
      
      {/* Add New Memo */}
      <div className="mb-6 flex gap-2">
        <input 
          type="text" 
          className="flex-1 border rounded-md px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none"
          placeholder="Type a memo (e.g. Needs second review)..." 
          value={newMemoText}
          onChange={(e) => setNewMemoText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleAddMemo()}
        />
        <button 
          onClick={handleAddMemo}
          className="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700 transition"
        >
          Add Note
        </button>
      </div>

      {/* Memos List */}
      <div className="space-y-4 max-h-64 overflow-y-auto pr-2">
        {memos.length === 0 ? (
          <p className="text-sm text-gray-400 italic text-center py-2">No memos recorded for this application.</p>
        ) : (
          memos.map(memo => (
            <div key={memo.memoId} className={`p-3 rounded-md border-l-4 ${memo.status === 'Pending' ? 'border-amber-400 bg-amber-50' : 'border-green-400 bg-green-50'}`}>
              <div className="flex justify-between items-start">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-sm text-gray-700">{memo.staffName}</span>
                  <span className="text-xs text-gray-500">{new Date(memo.createdAt).toLocaleString()}</span>
                  {memo.status === 'Pending' ? (
                    <span className="bg-amber-100 text-amber-800 text-[10px] px-2 py-0.5 rounded-full font-medium">Pending Review</span>
                  ) : (
                    <span className="bg-green-100 text-green-800 text-[10px] px-2 py-0.5 rounded-full font-medium">Resolved</span>
                  )}
                </div>
                
                {memo.status === 'Pending' && (
                  <div className="flex gap-2">
                    <button onClick={() => { setEditingMemoId(memo.memoId); setEditMemoText(memo.memoText); }} className="text-gray-400 hover:text-indigo-600" title="Edit Memo">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path></svg>
                    </button>
                    <button onClick={() => handleResolveMemo(memo.memoId)} className="text-gray-400 hover:text-green-600" title="Mark Resolved">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path></svg>
                    </button>
                    <button onClick={() => handleDeleteMemo(memo.memoId)} className="text-gray-400 hover:text-red-600" title="Delete Memo">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                    </button>
                  </div>
                )}
              </div>
              
              <div className="mt-2">
                {editingMemoId === memo.memoId ? (
                  <div className="flex gap-2">
                    <input 
                      type="text" 
                      className="flex-1 border-gray-300 rounded text-sm px-2 py-1"
                      value={editMemoText}
                      onChange={(e) => setEditMemoText(e.target.value)}
                    />
                    <button onClick={() => handleUpdateMemo(memo.memoId)} className="text-xs bg-indigo-100 text-indigo-700 px-2 py-1 rounded font-medium">Save</button>
                    <button onClick={() => setEditingMemoId(null)} className="text-xs text-gray-500 hover:text-gray-700">Cancel</button>
                  </div>
                ) : (
                  <p className={`text-sm ${memo.status === 'Resolved' ? 'text-gray-500 line-through' : 'text-gray-800'}`}>
                    {memo.memoText}
                  </p>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default InternalMemosPanel;
