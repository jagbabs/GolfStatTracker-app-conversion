import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Round, Hole } from '@shared/schema';
import { formatRelativeScore } from '@/lib/utils';

interface ScorecardProps {
  round: Round;
  holes: Hole[];
}

const Scorecard: React.FC<ScorecardProps> = ({ round, holes }) => {
  // Group holes into front 9 and back 9
  const frontNine = holes.filter(hole => hole.holeNumber <= 9);
  const backNine = holes.filter(hole => hole.holeNumber > 9);
  
  // Calculate totals
  const frontNineScore = frontNine.reduce((sum, hole) => sum + (hole.score || 0), 0);
  const backNineScore = backNine.reduce((sum, hole) => sum + (hole.score || 0), 0);
  const totalScore = frontNineScore + backNineScore;
  
  const frontNinePar = frontNine.reduce((sum, hole) => sum + (hole.par || 0), 0);
  const backNinePar = backNine.reduce((sum, hole) => sum + (hole.par || 0), 0);
  const totalPar = frontNinePar + backNinePar;
  
  // Calculate front 9, back 9, and total relativeToPar
  const frontNineRelative = frontNineScore ? frontNineScore - frontNinePar : null;
  const backNineRelative = backNineScore ? backNineScore - backNinePar : null;
  const totalRelative = totalScore ? totalScore - totalPar : null;
  
  // Calculations for other stats
  const fairwaysHit = holes.filter(hole => hole.fairwayHit).length;
  const greensInRegulation = holes.filter(hole => hole.greenInRegulation).length;
  const totalPutts = holes.reduce((sum, hole) => sum + (hole.numPutts || 0), 0);
  const upAndDowns = holes.filter(hole => hole.upAndDown).length;
  const sandSaves = holes.filter(hole => hole.sandSave).length;
  const penalties = holes.reduce((sum, hole) => sum + (hole.numPenalties || 0), 0);
  
  const getScoreClass = (score: number | null, par: number | null) => {
    if (score === null || par === null) return 'text-gray-400';
    
    const diff = score - par;
    
    if (diff < -1) return 'text-violet-600 font-bold'; // Eagle or better
    if (diff === -1) return 'text-red-600 font-bold'; // Birdie
    if (diff === 0) return 'text-black'; // Par
    if (diff === 1) return 'text-green-600'; // Bogey
    return 'text-blue-600'; // Double bogey or worse
  };
  
  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardContent className="p-4">
        <h3 className="text-xl font-semibold mb-4">Scorecard</h3>
        
        {/* Scorecard Table */}
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-200 text-sm">
            <thead>
              <tr className="bg-neutral-100">
                <th className="border px-2 py-1 text-left">Hole</th>
                {frontNine.map(hole => (
                  <th key={`hole-${hole.holeNumber}`} className="border px-2 py-1 text-center w-8">
                    {hole.holeNumber}
                  </th>
                ))}
                <th className="border px-2 py-1 text-center bg-neutral-200">Out</th>
                
                {backNine.map(hole => (
                  <th key={`hole-${hole.holeNumber}`} className="border px-2 py-1 text-center w-8">
                    {hole.holeNumber}
                  </th>
                ))}
                <th className="border px-2 py-1 text-center bg-neutral-200">In</th>
                <th className="border px-2 py-1 text-center bg-neutral-300">Total</th>
              </tr>
              
              <tr>
                <th className="border px-2 py-1 text-left">Par</th>
                {frontNine.map(hole => (
                  <td key={`par-${hole.holeNumber}`} className="border px-2 py-1 text-center font-medium">
                    {hole.par || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {frontNinePar || '-'}
                </td>
                
                {backNine.map(hole => (
                  <td key={`par-${hole.holeNumber}`} className="border px-2 py-1 text-center font-medium">
                    {hole.par || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {backNinePar || '-'}
                </td>
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-300">
                  {totalPar || '-'}
                </td>
              </tr>
              
              <tr>
                <th className="border px-2 py-1 text-left">Score</th>
                {frontNine.map(hole => (
                  <td 
                    key={`score-${hole.holeNumber}`} 
                    className={`border px-2 py-1 text-center ${getScoreClass(hole.score, hole.par)}`}
                  >
                    {hole.score || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {frontNineScore || '-'}
                </td>
                
                {backNine.map(hole => (
                  <td 
                    key={`score-${hole.holeNumber}`} 
                    className={`border px-2 py-1 text-center ${getScoreClass(hole.score, hole.par)}`}
                  >
                    {hole.score || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {backNineScore || '-'}
                </td>
                <td className="border px-2 py-1 text-center font-bold bg-neutral-300">
                  {totalScore || '-'}
                </td>
              </tr>
              
              <tr>
                <th className="border px-2 py-1 text-left">+/-</th>
                {frontNine.map(hole => {
                  const relativeToPar = hole.score && hole.par ? hole.score - hole.par : null;
                  return (
                    <td 
                      key={`rel-${hole.holeNumber}`} 
                      className={`border px-2 py-1 text-center ${getScoreClass(hole.score, hole.par)}`}
                    >
                      {relativeToPar !== null ? formatRelativeScore(relativeToPar) : '-'}
                    </td>
                  );
                })}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {frontNineRelative !== null ? formatRelativeScore(frontNineRelative) : '-'}
                </td>
                
                {backNine.map(hole => {
                  const relativeToPar = hole.score && hole.par ? hole.score - hole.par : null;
                  return (
                    <td 
                      key={`rel-${hole.holeNumber}`} 
                      className={`border px-2 py-1 text-center ${getScoreClass(hole.score, hole.par)}`}
                    >
                      {relativeToPar !== null ? formatRelativeScore(relativeToPar) : '-'}
                    </td>
                  );
                })}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {backNineRelative !== null ? formatRelativeScore(backNineRelative) : '-'}
                </td>
                <td className="border px-2 py-1 text-center font-bold bg-neutral-300">
                  {totalRelative !== null ? formatRelativeScore(totalRelative) : '-'}
                </td>
              </tr>
              
              <tr>
                <th className="border px-2 py-1 text-left">Putts</th>
                {frontNine.map(hole => (
                  <td 
                    key={`putts-${hole.holeNumber}`} 
                    className="border px-2 py-1 text-center"
                  >
                    {hole.numPutts || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {frontNine.reduce((sum, hole) => sum + (hole.numPutts || 0), 0) || '-'}
                </td>
                
                {backNine.map(hole => (
                  <td 
                    key={`putts-${hole.holeNumber}`} 
                    className="border px-2 py-1 text-center"
                  >
                    {hole.numPutts || '-'}
                  </td>
                ))}
                <td className="border px-2 py-1 text-center font-semibold bg-neutral-200">
                  {backNine.reduce((sum, hole) => sum + (hole.numPutts || 0), 0) || '-'}
                </td>
                <td className="border px-2 py-1 text-center font-bold bg-neutral-300">
                  {totalPutts || '-'}
                </td>
              </tr>
            </thead>
          </table>
        </div>
        
        {/* Summary Statistics */}
        <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Fairways Hit</h4>
            <p className="text-xl font-semibold">
              {fairwaysHit} / {holes.filter(h => h.par >= 4).length}
              <span className="text-sm text-neutral-500 ml-2">
                ({holes.filter(h => h.par >= 4).length ? Math.round((fairwaysHit / holes.filter(h => h.par >= 4).length) * 100) : 0}%)
              </span>
            </p>
          </div>
          
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Greens in Regulation</h4>
            <p className="text-xl font-semibold">
              {greensInRegulation} / {holes.length}
              <span className="text-sm text-neutral-500 ml-2">
                ({holes.length ? Math.round((greensInRegulation / holes.length) * 100) : 0}%)
              </span>
            </p>
          </div>
          
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Average Putts</h4>
            <p className="text-xl font-semibold">
              {holes.length ? (totalPutts / holes.length).toFixed(1) : '-'}
              <span className="text-sm text-neutral-500 ml-2">per hole</span>
            </p>
          </div>
          
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Penalties</h4>
            <p className="text-xl font-semibold">
              {penalties}
              <span className="text-sm text-neutral-500 ml-2">shots</span>
            </p>
          </div>
          
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Up & Downs</h4>
            <p className="text-xl font-semibold">
              {upAndDowns} successful
            </p>
          </div>
          
          <div className="bg-neutral-50 rounded p-3">
            <h4 className="text-xs uppercase text-neutral-500 mb-1">Sand Saves</h4>
            <p className="text-xl font-semibold">
              {sandSaves} successful
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default Scorecard;